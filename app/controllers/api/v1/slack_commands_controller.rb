require 'openssl' # 署名検証のために追加

class Api::V1::SlackCommandsController < ApplicationController
  # `commands`アクションの前に、必ず`verify_slack_request`メソッドを実行する
  before_action :verify_slack_request

  def commands
    # Slackからのリクエストのコマンドが'/memo'であるかを確認
    if params[:command] == '/memo'
      # Slackからのテキストをスペースで3つに分割し、それぞれを変数に代入
      # 例: "[カテゴリ] [キーワード] [内容]"
      category, keyword, *content_words = params[:text].split(' ')
      content = content_words.join(' ')

      # 必須項目が入力されているかチェック
      if category.present? && keyword.present? && content.present?
        # 新しいナレッジを作成
        knowledge = Knowledge.new(category: category, keyword: keyword, content: content)

        # データベースに保存
        if knowledge.save
          # 保存成功時のメッセージをSlackに返す
          render json: { text: "📝 #{knowledge.category}/#{knowledge.keyword} を保存しました！" }
        else
          # 保存失敗時のエラーメッセージをSlackに返す
          render json: { text: "🤯 保存に失敗しました: #{knowledge.errors.full_messages.join(', ')}" }
        end
      else
        # パラメータが不足している場合の使用方法をSlackに返す
        render json: { text: "🤔 使用方法: /memo [カテゴリ] [キーワード] [内容]" }
      end
    elsif params[:command] == '/search'
      # Slackからのテキストをスペースで2つに分割
      category, keyword = params[:text].split(' ')

      # 必須項目が入力されているかチェック
      if category.present? && keyword.present?
        # カテゴリとキーワードでナレッジを検索
        knowledges = Knowledge.where(category: category, keyword: keyword)

        if knowledges.present?
          # 見つかったナレッジの内容を整形して返す
          response_text = knowledges.map.with_index(1) do |k, i|
            "📖 *#{i}. #{k.category}/#{k.keyword}*\n> #{k.content}"
          end.join("\n\n")
          render json: { text: response_text }
        else
          # 見つからなかった場合のメッセージ
          render json: { text: "🤷‍♀️ ナレッジが見つかりませんでした: `#{category}/#{keyword}`" }
        end
      else
        # パラメータが不足している場合の使用方法をSlackに返す
        render json: { text: "🤔 使用方法: /search [カテゴリ] [キーワード]" }
      end
    else
      # '/memo'以外のコマンドが送られてきた場合のメッセージ
      render json: { text: "🤨 そのコマンドは知りません: #{params[:command]}" }
    end
  end

  private

  # Slackからのリクエストが正当なものか検証するメソッド
  def verify_slack_request
    # 1. 必要な情報を取得
    # 環境変数からSigning Secretを取得
    signing_secret = ENV['SLACK_SIGNING_SECRET']
    # リクエストヘッダーからタイムスタンプと署名を取得
    timestamp = request.headers['X-Slack-Request-Timestamp']
    signature = request.headers['X-Slack-Signature']
    # request.body.read はparamsが生成されると空になるため、生のPOSTデータを取得する
    request_body = request.raw_post

    # 2. そもそも情報が足りない場合は不正なリクエストとして弾く
    if signing_secret.nil? || timestamp.nil? || signature.nil?
      return head :bad_request
    end

    # 3. タイムスタンプが古すぎる場合はリプレイ攻撃とみなし、リクエストを弾く
    # (5分以上前のリクエストは無効)
    if Time.at(timestamp.to_i) < 5.minutes.ago
      return head :unauthorized
    end

    # 4. Slackの仕様通りに、署名の元となる文字列を組み立てる
    # フォーマット: "v0:[タイムスタンプ]:[リクエストボディ]"
    sig_basestring = "v0:#{timestamp}:#{request_body}"

    # 5. 組み立てた文字列とSigning Secretを使って、こちら側で署名を計算する
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)

    # 6. 計算した署名と、Slackから送られてきた署名が一致するかどうかを安全な方法で比較する
    # 一致しなければ不正なリクエストとして弾く
    unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
      return head :unauthorized
    end
  end
end

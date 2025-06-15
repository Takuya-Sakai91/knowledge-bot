class Api::V1::SlackCommandsController < ApplicationController
  # Slackからのリクエストの正当性を検証するために、RailsのCSRF保護を一時的に無効にします。
  # Slackは独自の方法（署名検証）でリクエストの信頼性を保証します。
  skip_before_action :verify_authenticity_token

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
    else
      # '/memo'以外のコマンドが送られてきた場合のメッセージ
      render json: { text: "🤨 そのコマンドは知りません: #{params[:command]}" }
    end
  end
end

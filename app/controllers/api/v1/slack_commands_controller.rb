require 'openssl'

class Api::V1::SlackCommandsController < ApplicationController
  before_action :verify_slack_request, only: [:create]

  # POST /api/v1/slack_commands
  def create
    case params[:command]
    when '/memo'
      category, content = params[:text].split(' ', 2)
      if content.nil?
        content = category
        category = nil
      end

      knowledge = Knowledge.new(category: category, content: content)

      if knowledge.save
        render plain: "ナレッジを登録しました：「#{content}」"
      else
        render plain: "エラーが発生しました: #{knowledge.errors.full_messages.join(', ')}", status: :internal_server_error
      end
    when '/find'
      keyword = params[:text]
      knowledges = Knowledge.search(keyword)

      if knowledges.present?
        render plain: knowledges.map { |k| "- #{k.content}" }.join("\n")
      else
        render plain: "「#{keyword}」に一致するナレッジは見つかりませんでした。"
      end
    when '/list'
      category = params[:text].strip
      if category.present?
        knowledges = Knowledge.where(category: category)
        if knowledges.present?
          render plain: knowledges.map { |k| "- #{k.content}" }.join("\n")
        else
          render plain: "カテゴリ「#{category}」にはナレッジが登録されていません。"
        end
      else
        render plain: "カテゴリを指定してください。例: /list Ruby"
      end
    when '/categories'
      categories = Knowledge.categories
      if categories.present?
        render plain: "登録されているカテゴリ一覧:\n- #{categories.join("\n- ")}"
      else
        render plain: "登録されているカテゴリはありません。"
      end
    else
      render plain: "不明なコマンドです: #{params[:command]}"
    end
  end

  private

  def verify_slack_request
    signing_secret = ENV['SLACK_SIGNING_SECRET']
    timestamp = request.headers['X-Slack-Request-Timestamp']
    signature = request.headers['X-Slack-Signature']
    request_body = request.raw_post

    if signing_secret.nil? || timestamp.nil? || signature.nil?
      return head :bad_request
    end

    if Time.at(timestamp.to_i) < 5.minutes.ago
      return head :unauthorized
    end

    sig_basestring = "v0:#{timestamp}:#{request_body}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)

    unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
      return head :unauthorized
    end
  end
end

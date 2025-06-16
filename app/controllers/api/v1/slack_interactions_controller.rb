require 'openssl'
require 'json'
require 'http'

class Api::V1::SlackInteractionsController < ApplicationController
  before_action :verify_slack_request, only: [:create]
  before_action :parse_slack_payload, only: [:create]

  def create
    action_id = @payload.dig(:actions, 0, :action_id)

    if action_id == 'delete_knowledge'
      handle_delete_knowledge
    else
      head :bad_request
    end
  end

  private

  def handle_delete_knowledge
    knowledge_id = @payload.dig(:actions, 0, :value)
    knowledge = Knowledge.find_by(id: knowledge_id)

    if knowledge
      knowledge.destroy
      update_original_message("✅ ナレッジ「#{truncate(knowledge.content)}」を削除しました。")
    else
      update_original_message("🤯 削除に失敗しました。指定されたナレッジが見つかりません。")
    end
  end

  def update_original_message(text)
    response_url = @payload[:response_url]

    updated_message = {
      replace_original: "true",
      text: text
    }

    # response_urlに対してPOSTリクエストを送る
    HTTP.post(response_url, json: updated_message)

    head :ok
  end

  def truncate(text, length: 20)
    text.length > length ? "#{text[0...length]}..." : text
  end

  # SlackCommandsControllerからコピーした署名検証ロジック
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

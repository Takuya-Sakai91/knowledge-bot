require 'openssl'
require 'json'

class Api::V1::SlackInteractionsController < ApplicationController
  before_action :verify_slack_request, only: [:create]

  def create
    payload = JSON.parse(params[:payload])

    # どのボタンが押されたかに応じて処理を分岐
    action_id = payload['actions'][0]['action_id']

    if action_id == 'delete_knowledge'
      knowledge_id = payload['actions'][0]['value']
      knowledge = Knowledge.find_by(id: knowledge_id)

      if knowledge
        knowledge.destroy
        # ここではシンプルに200 OKを返し、何もしない
        head :ok
      else
        # ナレッジが見つからない場合
        head :not_found
      end
    else
      # 不明なアクション
      head :bad_request
    end
  end

  private

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

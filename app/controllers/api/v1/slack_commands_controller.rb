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
        category = "未分類"
      end

      knowledge = Knowledge.new(category: category, content: content)

      if knowledge.save
        response_text = "📝 ナレッジを登録しました！\n> カテゴリ: `#{knowledge.category}`\n> 内容: #{knowledge.content}"
        render json: { text: response_text }
      else
        render json: { text: "🤯 エラーが発生しました: #{knowledge.errors.full_messages.join(', ')}" }
      end
    when '/find'
      keyword = params[:text]
      knowledges = Knowledge.search(keyword)

      if knowledges.present?
        blocks = []
        blocks << {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "🔍「#{keyword}」に一致するナレッジが見つかりました！"
          }
        }
        blocks << { type: "divider" }

        knowledges.each do |k|
          blocks << {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*カテゴリ: #{k.category}*\n> #{k.content}"
            }
          }
          blocks << {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "削除",
                  emoji: true
                },
                style: "danger",
                value: k.id.to_s,
                action_id: "delete_knowledge",
                confirm: {
                  title: {
                    type: "plain_text",
                    text: "本当に削除しますか？"
                  },
                  text: {
                    type: "mrkdwn",
                    text: "このナレッジを削除すると元に戻せません。"
                  },
                  confirm: {
                    type: "plain_text",
                    text: "削除する"
                  },
                  deny: {
                    type: "plain_text",
                    text: "キャンセル"
                  }
                }
              }
            ]
          }
          blocks << { type: "divider" }
        end

        render json: { blocks: blocks }
      else
        render json: { text: "🤔「#{keyword}」に一致するナレッジは見つかりませんでした。" }
      end
    when '/list'
      category = params[:text].strip
      if category.present?
        knowledges = Knowledge.where(category: category)
        if knowledges.present?
          blocks = []
          blocks << {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "📚 カテゴリ「#{category}」のナレッジ一覧です。"
            }
          }
          blocks << { type: "divider" }

          knowledges.each do |k|
            blocks << {
              type: "section",
              text: {
                type: "mrkdwn",
                text: "> #{k.content}"
              },
              accessory: {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "削除",
                  emoji: true
                },
                style: "danger",
                value: k.id.to_s,
                action_id: "delete_knowledge",
                confirm: {
                  title: {
                    type: "plain_text",
                    text: "本当に削除しますか？"
                  },
                  text: {
                    type: "mrkdwn",
                    text: "このナレッジを削除すると元に戻せません。"
                  },
                  confirm: {
                    type: "plain_text",
                    text: "削除する"
                  },
                  deny: {
                    type: "plain_text",
                    text: "キャンセル"
                  }
                }
              }
            }
          end
          render json: { blocks: blocks }
        else
          render json: { text: "🤔 カテゴリ「#{category}」にはナレッジが登録されていません。" }
        end
      else
        render json: { text: "🤔 カテゴリを指定してください。例: /list Ruby" }
      end
    when '/categories'
      categories = Knowledge.categories
      if categories.present?
        response_text = "🗂️ 登録されているカテゴリ一覧です。\n"
        response_text += categories.map { |c| "> • #{c}" }.join("\n")
        render json: { text: response_text }
      else
        render json: { text: "🤔 登録されているカテゴリはありません。" }
      end
    else
      render json: { text: "🤔 不明なコマンドです: #{params[:command]}" }
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

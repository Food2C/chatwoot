require 'net/http'
require 'json'

class Food2cClassificationVerifier
  def self.status(conversation)
    base_url = ENV.fetch('FOOD2C_TEMPLATE_APP_URL', '').delete_suffix('/')
    secret = ENV.fetch('FOOD2C_TEMPLATE_APP_SECRET', '')
    return :unavailable if base_url.blank? || secret.blank?

    uri = URI.parse("#{base_url}/classifications/status")
    return :unavailable unless uri.is_a?(URI::HTTPS)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{secret}"
    request['Content-Type'] = 'application/json'
    request.body = {
      chatwoot_account_id: conversation.account_id,
      chatwoot_inbox_id: conversation.inbox_id,
      chatwoot_conversation_id: conversation.id,
      tabulation: conversation.custom_attributes['food2c_tabulation']
    }.to_json
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 2, read_timeout: 3) do |http|
      http.request(request)
    end
    return :unavailable unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['classified'] == true ? :confirmed : :missing
  rescue StandardError => e
    Rails.logger.warn("Food2C tabulation verification failed: #{e.class}: #{e.message}")
    :unavailable
  end
end

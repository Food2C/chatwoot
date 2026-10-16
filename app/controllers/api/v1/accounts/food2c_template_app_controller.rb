require 'net/http'

class Api::V1::Accounts::Food2cTemplateAppController < Api::V1::Accounts::BaseController
  # The page contains no credentials. Its API requests still require the agent's
  # Chatwoot session and are restricted to the account in the URL.
  skip_before_action :authenticate_user!, only: :show
  skip_before_action :current_account, only: :show
  before_action :ensure_human_user, only: [:channels, :proxy]

  ENDPOINTS = %w[
    templates customer customers/search history send classification-options
    classifications/context classifications/save classifications/report
  ].freeze

  def show
    upstream = upstream_request("#{params[:page]}")
    response.headers['Content-Security-Policy'] = upstream['Content-Security-Policy'] if upstream['Content-Security-Policy'].present?
    response.headers['Cache-Control'] = 'no-store'
    render body: upstream.body, status: upstream.code.to_i, content_type: 'text/html'
  rescue StandardError => e
    render_upstream_error(e)
  end

  def channels
    upstream = upstream_request('channels', bearer: true)
    return relay(upstream) unless upstream.is_a?(Net::HTTPSuccess)

    data = JSON.parse(upstream.body)
    data['channels'] = Array(data['channels']).select { |item| item['chatwoot_account_id'].to_i == Current.account.id }
    response.headers['Cache-Control'] = 'no-store'
    render json: data
  rescue StandardError => e
    render_upstream_error(e)
  end

  def proxy
    endpoint = params[:endpoint] || "classifications/#{params[:action_name]}"
    return head :not_found unless ENDPOINTS.include?(endpoint)

    payload = JSON.parse(request.raw_post)
    return render json: { error: 'invalid_request' }, status: :bad_request unless payload.is_a?(Hash)
    return head :forbidden if payload['chatwoot_account_id'].present? && payload['chatwoot_account_id'].to_i != Current.account.id
    return head :forbidden if endpoint == 'classification-options' && payload['action'] != 'list' && !Current.account_user.administrator?

    payload['chatwoot_account_id'] = Current.account.id
    if endpoint == 'classifications/save'
      payload['classified_by_id'] = Current.user.id
      payload['classified_by_name'] = Current.user.name
    end
    relay(upstream_request(endpoint, body: payload.to_json, bearer: true))
  rescue JSON::ParserError
    render json: { error: 'invalid_json' }, status: :bad_request
  rescue StandardError => e
    render_upstream_error(e)
  end

  private

  def ensure_human_user
    head :forbidden unless Current.user.is_a?(User) && Current.account_user.present?
  end

  def upstream_request(endpoint, body: nil, bearer: false)
    base_url = ENV.fetch('FOOD2C_TEMPLATE_APP_URL', '').delete_suffix('/')
    uri = URI.parse("#{base_url}/#{endpoint}")
    raise ArgumentError, 'FOOD2C_TEMPLATE_APP_URL must use HTTPS' unless uri.is_a?(URI::HTTPS)

    request_class = body.nil? ? Net::HTTP::Get : Net::HTTP::Post
    upstream = request_class.new(uri)
    if bearer
      secret = ENV.fetch('FOOD2C_TEMPLATE_APP_SECRET', '')
      raise ArgumentError, 'FOOD2C_TEMPLATE_APP_SECRET is missing' if secret.blank?

      upstream['Authorization'] = "Bearer #{secret}"
    end
    upstream['Content-Type'] = 'application/json' if body
    upstream.body = body if body
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) { |http| http.request(upstream) }
  end

  def relay(upstream)
    response.headers['Cache-Control'] = 'no-store'
    render body: upstream.body, status: upstream.code.to_i, content_type: 'application/json'
  end

  def render_upstream_error(error)
    Rails.logger.error("Food2C Template App proxy failed: #{error.class}: #{error.message}")
    render json: { error: 'food2c_unavailable' }, status: :bad_gateway
  end
end

require 'rails_helper'

RSpec.describe 'Food2C Template App proxy', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/food2c/template-app" }
  let(:upstream_url) { 'https://api.food2c.example/template-app' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('FOOD2C_TEMPLATE_APP_URL', '').and_return(upstream_url)
    allow(ENV).to receive(:fetch).with('FOOD2C_TEMPLATE_APP_SECRET', '').and_return('server-secret')
  end

  it 'requires a Chatwoot login for channel data' do
    get "#{base_path}/channels"

    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns only channels in the agent account' do
    stub_request(:get, "#{upstream_url}/channels")
      .with(headers: { 'Authorization' => 'Bearer server-secret' })
      .to_return(status: 200, body: { channels: [
        { chatwoot_account_id: account.id, chatwoot_inbox_id: 1 },
        { chatwoot_account_id: account.id + 1, chatwoot_inbox_id: 2 }
      ] }.to_json, headers: { 'Content-Type' => 'application/json' })

    get "#{base_path}/channels", headers: agent.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['channels'].pluck('chatwoot_inbox_id')).to eq([1])
  end

  it 'rejects requests for another account before contacting Food2C' do
    post "#{base_path}/templates", headers: agent.create_new_auth_token,
                                   params: { chatwoot_account_id: account.id + 1, chatwoot_inbox_id: 1 }, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(WebMock).not_to have_requested(:post, "#{upstream_url}/templates")
  end

  it 'forwards requests with the server secret and account scope' do
    upstream = stub_request(:post, "#{upstream_url}/templates")
    upstream.with do |request|
      request.headers['Authorization'] == 'Bearer server-secret' &&
        JSON.parse(request.body)['chatwoot_account_id'] == account.id
    end
    upstream.to_return(status: 200, body: { templates: [] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })

    post "#{base_path}/templates", headers: agent.create_new_auth_token,
                                   params: { chatwoot_inbox_id: 1 }, as: :json

    expect(response).to have_http_status(:ok)
    expect(upstream).to have_been_requested
  end

  it 'restricts tabulation configuration changes to account administrators' do
    post "#{base_path}/classification-options", headers: agent.create_new_auth_token,
                                                  params: { action: 'create', kind: 'tabulation', name: 'Venda' }, as: :json

    expect(response).to have_http_status(:forbidden)
  end
end

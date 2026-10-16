require 'rails_helper'

RSpec.describe Food2cClassificationVerifier do
  let(:conversation) do
    create(:conversation, custom_attributes: { food2c_tabulation: 'Venda concluída' })
  end
  let(:status_url) { 'https://api.food2c.example/template-app/classifications/status' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('FOOD2C_TEMPLATE_APP_URL', '').and_return('https://api.food2c.example/template-app')
    allow(ENV).to receive(:fetch).with('FOOD2C_TEMPLATE_APP_SECRET', '').and_return('server-secret')
  end

  it 'confirms only a synced classification matching the conversation' do
    request = stub_request(:post, status_url).with do |incoming|
      payload = JSON.parse(incoming.body)
      incoming.headers['Authorization'] == 'Bearer server-secret' &&
        payload['chatwoot_account_id'] == conversation.account_id &&
        payload['chatwoot_inbox_id'] == conversation.inbox_id &&
        payload['chatwoot_conversation_id'] == conversation.id &&
        payload['tabulation'] == 'Venda concluída'
    end
    request.to_return(status: 200, body: { classified: true }.to_json)

    expect(described_class.status(conversation)).to eq(:confirmed)
    expect(request).to have_been_requested
  end

  it 'rejects an unsynced classification' do
    stub_request(:post, status_url).to_return(status: 200, body: { classified: false }.to_json)

    expect(described_class.status(conversation)).to eq(:missing)
  end

  it 'fails closed when Food2C cannot verify the classification' do
    stub_request(:post, status_url).to_return(status: 503)

    expect(described_class.status(conversation)).to eq(:unavailable)
  end
end

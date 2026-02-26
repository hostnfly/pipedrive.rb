# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Activity do
  subject { described_class.new('token') }

  describe '#entity_name' do
    it { expect(subject.entity_name).to eq('activities') }
  end

  describe '#build_url' do
    it 'uses /api/v2/activities' do
      expect(subject.build_url([])).to eq('/api/v2/activities')
    end

    it 'appends id when provided' do
      expect(subject.build_url([nil, 42])).to eq('/api/v2/activities/42')
    end

    it 'does not include api_token as query param' do
      expect(subject.build_url([])).not_to include('api_token')
    end
  end

  describe '#connection' do
    it 'authenticates via x-api-token header' do
      expect(subject.connection.headers['x-api-token']).to eq('token')
    end
  end

  describe '#create' do
    it 'POSTs to /api/v2/activities with x-api-token header' do
      stub_request(:post, 'https://api.pipedrive.com/api/v2/activities')
        .with(headers: { 'x-api-token' => 'token' })
        .to_return(status: 200, body: { success: true, data: {} }.to_json, headers: {})
      expect(subject.create(subject: 'Call', type: 'call')).to be_success
    end
  end

  describe '#find_by_id' do
    it 'GETs /api/v2/activities/:id with x-api-token header' do
      stub_request(:get, 'https://api.pipedrive.com/api/v2/activities/1')
        .with(headers: { 'x-api-token' => 'token' })
        .to_return(status: 200, body: { success: true, data: {} }.to_json, headers: {})
      expect(subject.find_by_id(1)).to be_success
    end
  end

  describe '#update' do
    it 'PATCHes /api/v2/activities/:id with x-api-token header' do
      stub_request(:patch, 'https://api.pipedrive.com/api/v2/activities/1')
        .with(headers: { 'x-api-token' => 'token' })
        .to_return(status: 200, body: { success: true, data: {} }.to_json, headers: {})
      expect(subject.update(1, subject: 'Updated call')).to be_success
    end
  end

  describe '#delete' do
    it 'DELETEs /api/v2/activities/:id with x-api-token header' do
      stub_request(:delete, 'https://api.pipedrive.com/api/v2/activities/1')
        .with(headers: { 'x-api-token' => 'token' })
        .to_return(status: 200, body: { success: true }.to_json, headers: {})
      expect(subject.delete(1)).to be_success
    end
  end

  describe '#all' do
    it 'uses cursor-based pagination' do
      stub_request(:get, 'https://api.pipedrive.com/api/v2/activities')
        .with(headers: { 'x-api-token' => 'token' })
        .to_return(
          status: 200,
          body: { success: true, data: [{ id: 1 }, { id: 2 }], additional_data: { next_cursor: 'abc' } }.to_json,
          headers: {}
        )
      stub_request(:get, 'https://api.pipedrive.com/api/v2/activities')
        .with(headers: { 'x-api-token' => 'token' }, query: { 'cursor' => 'abc' })
        .to_return(
          status: 200,
          body: { success: true, data: [{ id: 3 }], additional_data: { next_cursor: nil } }.to_json,
          headers: {}
        )
      expect(subject.all.length).to eq(3)
    end
  end

  describe '#each' do
    it 'supports filtering by owner_id' do
      stub_request(:get, 'https://api.pipedrive.com/api/v2/activities')
        .with(headers: { 'x-api-token' => 'token' }, query: { 'owner_id' => '5' })
        .to_return(
          status: 200,
          body: { success: true, data: [{ id: 1 }], additional_data: { next_cursor: nil } }.to_json,
          headers: {}
        )
      expect { |b| subject.each({ owner_id: 5 }, &b) }.to yield_successive_args(::Hashie::Mash.new(id: 1))
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Base do
  subject { described_class.new('token') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq described_class.name.split('::')[-1].downcase.pluralize }
  end

  context '::faraday_options' do
    subject { described_class.faraday_options }

    it 'keeps the same base URL as v1' do
      expect(subject[:url]).to eq('https://api.pipedrive.com')
    end
  end

  context '::connection' do
    subject { super().connection }

    it { is_expected.to be_kind_of(::Faraday::Connection) }
  end

  describe '#connection' do
    it 'sets x-api-token header from api_token' do
      expect(subject.connection.headers['x-api-token']).to eq('token')
    end

    it 'does not pollute the class-level connection headers' do
      described_class.new('token_a').connection
      described_class.new('token_b').connection
      expect(described_class.connection.headers['x-api-token']).to be_nil
    end
  end

  describe '#build_url' do
    it 'uses /api/v2/ prefix' do
      expect(subject.build_url([])).to start_with('/api/v2/')
    end

    it 'does not include api_token as query param' do
      expect(subject.build_url([])).not_to include('api_token')
    end

    it 'appends id when provided' do
      expect(subject.build_url([nil, 42])).to end_with('/42')
    end

    it 'ignores fields_to_select' do
      expect(subject.build_url([], %w[a b c])).not_to include(':(')
    end
  end

  describe '#make_api_call' do
    let(:entity) { described_class.name.split('::')[-1].downcase.pluralize }

    it 'fails with no method' do
      expect { subject.make_api_call(test: 'foo') }.to raise_error('method param missing')
    end

    context 'without id' do
      it 'calls :get with v2 path and x-api-token header' do
        stub_request(:get, "https://api.pipedrive.com/api/v2/#{entity}")
          .with(headers: { 'x-api-token' => 'token' })
          .to_return(status: 200, body: {}.to_json, headers: {})
        expect(subject.make_api_call(:get)).to be_success
      end

      it 'calls :post with v2 path' do
        stub_request(:post, "https://api.pipedrive.com/api/v2/#{entity}")
          .with(headers: { 'x-api-token' => 'token' })
          .to_return(status: 200, body: {}.to_json, headers: {})
        expect(subject.make_api_call(:post, test: 'bar')).to be_success
      end
    end

    context 'with id' do
      it 'calls :get with id in path' do
        stub_request(:get, "https://api.pipedrive.com/api/v2/#{entity}/12")
          .with(headers: { 'x-api-token' => 'token' })
          .to_return(status: 200, body: {}.to_json, headers: {})
        expect(subject.make_api_call(:get, 12)).to be_success
      end

      it 'calls :patch with id in path' do
        stub_request(:patch, "https://api.pipedrive.com/api/v2/#{entity}/14")
          .with(headers: { 'x-api-token' => 'token' })
          .to_return(status: 200, body: {}.to_json, headers: {})
        expect(subject.make_api_call(:patch, 14, test: 'bar')).to be_success
      end
    end
  end
end

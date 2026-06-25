# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::Base do
  subject { described_class.new('token') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq described_class.name.split('::')[-1].downcase.pluralize }
  end

  context '::faraday_options' do
    subject { described_class.faraday_options }

    it {
      expect(subject).to eq({
                              url:     'https://api.pipedrive.com',
      headers: { accept: 'application/json', user_agent: "Pipedrive Ruby Client v#{::Pipedrive::VERSION}" }
                            })
    }
  end

  context '::connection' do
    subject { super().connection }

    it { is_expected.to be_kind_of(::Faraday::Connection) }
  end

  describe '#failed_response' do
    subject { super().failed_response(res) }

    let(:res) { double('res', body: ::Hashie::Mash.new({}), status: status) }

    context 'status is 400' do
      let(:status) { 400 }
      it { expect { subject }.to raise_error(::Pipedrive::BadRequestError) }
    end

    context 'status is 401' do
      let(:status) { 401 }
      it { expect { subject }.to raise_error(::Pipedrive::UnauthorizedError) }
    end

    context 'status is 403' do
      let(:status) { 403 }
      it { expect { subject }.to raise_error(::Pipedrive::ForbiddenError) }
    end

    context 'status is 404' do
      let(:status) { 404 }
      it { expect { subject }.to raise_error(::Pipedrive::NotFoundError) }
    end

    context 'status is 429' do
      let(:status) { 429 }
      it { expect { subject }.to raise_error(::Pipedrive::RateLimitError) }
    end

    context 'status is 500' do
      let(:status) { 500 }
      it { expect { subject }.to raise_error(::Pipedrive::APIError) }
    end
  end

  describe '#make_api_call' do
    it 'faileds no method' do
      expect { subject.make_api_call(test: 'foo') }.to raise_error('method param missing')
    end

    context 'without id' do
      it 'calls :get' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get).with('/v1/bases?api_token=token', {}).and_call_original
        expect(subject.make_api_call(:get))
      end

      it 'calls :post' do
        stub_request(:post, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:post).with('/v1/bases?api_token=token', { test: 'bar' }).and_call_original
        expect(subject.make_api_call(:post, test: 'bar'))
      end

      it 'calls :put' do
        stub_request(:put, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:put).with('/v1/bases?api_token=token', { test: 'bar' }).and_call_original
        expect(subject.make_api_call(:put, test: 'bar'))
      end

      it 'uses field_selector properly' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases:(a,b,c)?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get)
          .with('/v1/bases:(a,b,c)?api_token=token', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: %w[a b c]))
      end

      it 'does not use field_selector if it empty' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get)
          .with('/v1/bases?api_token=token', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: []))
      end

      it 'retries if Errno::ETIMEDOUT' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        connection = subject.connection
        allow(subject).to receive(:connection).and_return(connection)
        allow(connection).to receive(:get)
          .with('/v1/bases?api_token=token', {}).and_raise(Errno::ETIMEDOUT)
        expect(connection).to receive(:get)
          .with('/v1/bases?api_token=token', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: []))
      end
    end

    context 'with id' do
      it 'calls :get' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases/12?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get).with('/v1/bases/12?api_token=token', {}).and_call_original
        expect(subject.make_api_call(:get, 12))
      end

      it 'calls :post' do
        stub_request(:post, 'https://api.pipedrive.com/v1/bases/13?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:post).with('/v1/bases/13?api_token=token', { test: 'bar' }).and_call_original
        expect(subject.make_api_call(:post, 13, test: 'bar'))
      end

      it 'calls :put' do
        stub_request(:put, 'https://api.pipedrive.com/v1/bases/14?api_token=token').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:put).with('/v1/bases/14?api_token=token', { test: 'bar' }).and_call_original
        expect(subject.make_api_call(:put, 14, test: 'bar'))
      end
    end

    it 'returns success: true for empty body' do
      stub_request(:get, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 200, body: '', headers: {})
      expect(subject.make_api_call(:get).success).to be true
    end

    it 'raises an error if failed status' do
      stub_request(:get, 'https://api.pipedrive.com/v1/bases?api_token=token').to_return(status: 400, body: {}.to_json, headers: {})
      expect { subject.make_api_call(:get) }.to raise_error(::Pipedrive::APIError)
    end
  end
end

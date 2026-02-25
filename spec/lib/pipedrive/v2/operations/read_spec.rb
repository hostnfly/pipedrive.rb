# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Operations::Read do
  subject do
    Class.new(::Pipedrive::V2::Base) do
      include ::Pipedrive::V2::Operations::Read
    end.new('token')
  end

  describe '#find_by_id' do
    it 'calls #make_api_call' do
      expect(subject).to receive(:make_api_call).with(:get, 12)
      subject.find_by_id(12)
    end
  end

  describe '#each' do
    it 'returns Enumerator if no block given' do
      expect(subject.each).to be_a(::Enumerator)
    end

    it 'calls to_enum with params' do
      expect(subject).to receive(:to_enum).with(:each, { foo: 'bar' })
      subject.each(foo: 'bar')
    end

    it 'yields data from a single page' do
      expect(subject).to receive(:chunk).and_return(
        ::Hashie::Mash.new(data: [1, 2], success: true, additional_data: { next_cursor: nil })
      )
      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2)
    end

    it 'follows cursor-based pagination' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(data: [1, 2], success: true, additional_data: { next_cursor: 'abc' })
      )
      expect(subject).to receive(:chunk).with(cursor: 'abc').and_return(
        ::Hashie::Mash.new(data: [3, 4], success: true, additional_data: { next_cursor: nil })
      )
      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2, 3, 4)
    end

    it 'does not yield anything if result has no data' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(success: true)
      )
      expect { |b| subject.each(&b) }.to yield_successive_args
    end

    it 'does not yield anything if result is not success' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(success: false)
      )
      expect { |b| subject.each(&b) }.to yield_successive_args
    end
  end

  describe '#all' do
    it 'calls #each and returns array' do
      arr = double('enumerator')
      allow(arr).to receive(:to_a)
      expect(subject).to receive(:each).and_return(arr)
      subject.all
    end
  end

  describe '#chunk' do
    it 'returns [] on failed response' do
      res = double('res', success?: false)
      expect(subject).to receive(:make_api_call).with(:get, {}).and_return(res)
      expect(subject.chunk).to eq([])
    end

    it 'returns result on success' do
      res = double('res', success?: true)
      expect(subject).to receive(:make_api_call).with(:get, {}).and_return(res)
      expect(subject.chunk).to eq(res)
    end
  end
end

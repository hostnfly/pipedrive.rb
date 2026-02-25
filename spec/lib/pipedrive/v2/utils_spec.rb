# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Utils do
  subject do
    Class.new(::Pipedrive::V2::Base) do
      include ::Pipedrive::V2::Utils
    end.new('token')
  end

  describe '#follow_pagination' do
    it 'yields all items from a single page with no next cursor' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(data: [1, 2], success: true, additional_data: { next_cursor: nil })
      )
      results = []
      subject.follow_pagination(:chunk, [], {}) { |item| results << item }
      expect(results).to eq([1, 2])
    end

    it 'follows cursor across multiple pages' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(data: [1, 2], success: true, additional_data: { next_cursor: 'abc' })
      )
      expect(subject).to receive(:chunk).with(cursor: 'abc').and_return(
        ::Hashie::Mash.new(data: [3, 4], success: true, additional_data: { next_cursor: nil })
      )
      results = []
      subject.follow_pagination(:chunk, [], {}) { |item| results << item }
      expect(results).to eq([1, 2, 3, 4])
    end

    it 'stops when response has no data' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(success: true)
      )
      results = []
      subject.follow_pagination(:chunk, [], {}) { |item| results << item }
      expect(results).to be_empty
    end

    it 'stops when response is not successful' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(success: false)
      )
      results = []
      subject.follow_pagination(:chunk, [], {}) { |item| results << item }
      expect(results).to be_empty
    end

    it 'does not send cursor param on first request' do
      expect(subject).to receive(:chunk) do |params|
        expect(params).not_to have_key(:cursor)
        ::Hashie::Mash.new(data: [], success: true)
      end
      subject.follow_pagination(:chunk, [], {}) { }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Operations::Update do
  subject do
    Class.new(::Pipedrive::V2::Base) do
      include ::Pipedrive::V2::Operations::Update
    end.new('token')
  end

  describe '#update' do
    it 'calls #make_api_call with :patch' do
      expect(subject).to receive(:make_api_call).with(:patch, 12, { foo: 'bar' })
      subject.update(12, foo: 'bar')
    end

    it 'calls #make_api_call with id in params' do
      expect(subject).to receive(:make_api_call).with(:patch, 14, { foo: 'bar' })
      subject.update(foo: 'bar', id: 14)
    end

    it 'raises when id is missing' do
      expect { subject.update(foo: 'bar') }.to raise_error('id must be provided')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Operations::Delete do
  subject do
    Class.new(::Pipedrive::V2::Base) do
      include ::Pipedrive::V2::Operations::Delete
    end.new('token')
  end

  describe '#delete' do
    it 'calls #make_api_call with :delete and id' do
      expect(subject).to receive(:make_api_call).with(:delete, 12)
      subject.delete(12)
    end
  end

  describe '#delete_all' do
    it 'calls #make_api_call with :delete' do
      expect(subject).to receive(:make_api_call).with(:delete)
      subject.delete_all
    end
  end
end

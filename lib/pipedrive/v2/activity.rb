# frozen_string_literal: true

module Pipedrive
  module V2
    class Activity < ::Pipedrive::V2::Base
      include ::Pipedrive::V2::Operations::Create
      include ::Pipedrive::V2::Operations::Read
      include ::Pipedrive::V2::Operations::Update
      include ::Pipedrive::V2::Operations::Delete
    end
  end
end

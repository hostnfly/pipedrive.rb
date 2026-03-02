# frozen_string_literal: true

module Pipedrive
  module V2
    module Operations
      module Create
        extend ActiveSupport::Concern

        def create(params)
          make_api_call(:post, params)
        end
      end
    end
  end
end

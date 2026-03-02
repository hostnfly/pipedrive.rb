# frozen_string_literal: true

module Pipedrive
  module V2
    module Operations
      module Read
        extend ActiveSupport::Concern
        include ::Enumerable
        include ::Pipedrive::V2::Utils

        def each(params = {}, &block)
          return to_enum(:each, params) unless block_given?

          follow_pagination(:chunk, [], params, &block)
        end

        def all(params = {})
          each(params).to_a
        end

        def chunk(params = {})
          res = make_api_call(:get, params)
          return [] unless res.success?

          res
        end

        def find_by_id(id)
          make_api_call(:get, id)
        end
      end
    end
  end
end

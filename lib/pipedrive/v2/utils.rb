# frozen_string_literal: true

module Pipedrive
  module V2
    module Utils
      extend ActiveSupport::Concern

      def follow_pagination(method, args, params, &block)
        cursor = nil
        loop do
          pagination_params = cursor ? params.merge(cursor: cursor) : params
          res = __send__(method, *args, pagination_params)
          break if !res.try(:data) || !res.success?

          res.data.each(&block)
          cursor = res.try(:additional_data).try(:next_cursor)
          break if cursor.nil?
        end
      end
    end
  end
end

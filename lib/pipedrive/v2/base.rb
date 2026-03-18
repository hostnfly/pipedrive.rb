# frozen_string_literal: true

module Pipedrive
  module V2
    class Base < ::Pipedrive::Base
      class << self
        private

        # V2 API requires JSON request bodies to preserve integer types.
        def params_format
          :json
        end
      end

      def build_url(args, _fields_to_select = nil)
        url = +"/api/v2/#{entity_name}"
        url << "/#{args[1]}" if args[1]
        url
      end

      def connection
        conn = self.class.connection.dup
        conn.headers['x-api-token'] = @api_token
        conn
      end
    end
  end
end

# frozen_string_literal: true

module Pipedrive
  class APIError < StandardError
    attr_reader :status, :code

    def initialize(error, status, code=nil)
      super(error)
      @status = status
      @code = code
    end
  end

  RateLimitError = Class.new(APIError)
  NotFoundError = Class.new(APIError)
  BadRequestError = Class.new(APIError)
  UnauthorizedError = Class.new(APIError)
  ForbiddenError = Class.new(APIError)

  class Base
    def initialize(api_token = ::Pipedrive.api_token)
      raise 'api_token should be set' unless api_token.present?

      @api_token = api_token
    end

    def connection
      self.class.connection.dup
    end

    def make_api_call(*args)
      params = args.extract_options!
      method = args[0]
      raise 'method param missing' unless method.present?

      begin
        url = build_url(args, params.delete(:fields_to_select))
        res = connection.__send__(method.to_sym, url, params)
      rescue Faraday::ParsingError => e
        res = e.response
      end
      process_response(res).merge(status: res.status)
    end

    def build_url(args, fields_to_select = nil)
      url = +"/v1/#{entity_name}"
      url << "/#{args[1]}" if args[1]
      url << ":(#{fields_to_select.join(',')})" if fields_to_select.is_a?(::Array) && fields_to_select.size.positive?
      url << "?api_token=#{@api_token}"
      url
    end

    def process_response(res)
      if res.success?
        data = if res.body.is_a?(::Hashie::Mash)
                 res.body.merge(success: true)
               else
                 ::Hashie::Mash.new(success: true)
               end
        return data
      end
      failed_response(res)
    end

    def failed_response(res)
      if res.body.is_a?(::Hashie::Mash)
        data = res.body
      else
        data = ::Hashie::Mash.new(error: 'Unknown error', code: nil)
      end

      case res.status
      when 400
        raise BadRequestError.new(data.error, res.status, data.code)
      when 401
        raise UnauthorizedError.new(data.error, res.status)
      when 403
        raise ForbiddenError.new(data.error, res.status)
      when 404
        raise NotFoundError.new(data.error, res.status, data.code)
      when 429
        raise RateLimitError.new('Rate limit exceeded', res.status)
      end
      raise APIError.new(data.error, res.status, data.code)
    end

    def entity_name
      class_name = self.class.name.split('::')[-1].downcase.pluralize
      class_names = { 'people' => 'persons' }
      class_names[class_name] || class_name
    end

    class << self
      def faraday_options
        {
          url:     'https://api.pipedrive.com',
          headers: {
            accept:     'application/json',
            user_agent: ::Pipedrive.user_agent
          }
        }
      end

      # This method smells of :reek:TooManyStatements
      # :nodoc
      def connection
        @connection ||= Faraday.new(faraday_options) do |conn|
          conn.request params_format
          conn.response :mashify
          conn.response :json, content_type: /\bjson$/
          conn.use FaradayMiddleware::ParseJson
          conn.response :logger, ::Pipedrive.logger if ::Pipedrive.debug
          conn.adapter Faraday.default_adapter
        end
      end

      private

      def params_format
        :url_encoded
      end
    end
  end
end

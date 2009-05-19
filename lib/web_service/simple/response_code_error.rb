module WebService
  class Simple
    class ResponseCodeError < RuntimeError
      attr_reader :response_code
      attr_reader :response_body

      def initialize(response)
        @response_code = response.code
        @response_body = response.body
      end

      def to_s
        "#{ response_code } => #{ Net::HTTPResponse::CODE_TO_OBJ[response_code] }"
      end

      def inspect; to_s; end
    end
  end
end

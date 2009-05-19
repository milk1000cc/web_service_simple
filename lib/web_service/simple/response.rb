module WebService
  class Simple
    class Response
      attr_reader :content

      def initialize(content, parser)
        @content = content
        @parser = parser
      end

      def parse_response
        @parser.parse_response self
      end
    end
  end
end

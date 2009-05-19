require 'rubygems'
require 'nokogiri'

module WebService
  class Simple
    class Parser
      module XML
        class Nokogiri < Parser
          def parse_response(response)
            ::Nokogiri::XML response.content
          end
        end
      end
    end
  end
end

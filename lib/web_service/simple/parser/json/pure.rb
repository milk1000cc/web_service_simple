require 'rubygems'
require 'json/pure'

module WebService
  class Simple
    class Parser
      class JSON < Parser
        class Pure < Parser
          def parse_response(response)
            ::JSON.parse response.content
          end
        end
      end
    end
  end
end

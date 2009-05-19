require 'rubygems'
require 'json'

module WebService
  class Simple
    class Parser
      class JSON < Parser
        def parse_response(response)
          ::JSON.parse response.content
        end
      end
    end
  end
end

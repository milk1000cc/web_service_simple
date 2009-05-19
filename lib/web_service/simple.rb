require 'logger'
require 'net/http'
require 'uri'

require 'web_service/simple/response'
require 'web_service/simple/response_code_error'
require 'web_service/simple/parser'

module WebService
  class Simple
    VERSION = '0.0.1'

    attr_accessor :base_url
    attr_accessor :basic_params
    attr_accessor :response_parser
    attr_accessor :logger
    attr_accessor :debug

    @@config = {
      :base_url => nil,
      :response_parser => { :module => 'XML::Nokogiri' }
    }

    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end

    def response_parser
      unless @response_parser and @response_parser.is_a?(Parser)
        klass = @response_parser.is_a?(Hash) ? @response_parser[:module] : @response_parser
        klass = "Simple::Parser::#{ klass }"
        require File.expand_path(underscore(klass), File.dirname(__FILE__))
        @response_parser = eval(klass).new
      end
      @response_parser
    end

    def initialize(arg = {})
      Net::HTTP.version_1_2

      @base_url = arg[:base_url] || @@config[:base_url]
      raise ArgumentError, 'base_url is required' unless @base_url

      @logger = arg[:logger]
      @debug = arg[:debug] || false
      @basic_params = arg[:params] || arg[:param] || {}
      @response_parser = arg[:response_parser] || @@config[:response_parser]
    end

    def get(*args)
      extra_path, extra_params = nil, {}

      if args.first.is_a?(Hash)
        extra_params = args.shift
      else
        extra_path = args.shift
        extra_params = args.shift if args.first.is_a?(Hash)
      end

      params = @basic_params.merge(extra_params).map { |k, v| "#{ URI.escape(k.to_s) }=#{ URI.escape(v.to_s) }" } * '&'
      uri = URI("#{ @base_url }#{ extra_path }?#{ params }")

      log "Request URL is #{ uri }"

      response = nil
      Net::HTTP.start(uri.host, uri.port) { |http|
        req = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(req)
      }
      raise ResponseCodeError.new(response) unless response.code == '200'

      Response.new(response.body, response_parser)
    end

    private
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def log(message)
      logger.info "[simple_web_service] #{message}" if @debug
    end
  end
end

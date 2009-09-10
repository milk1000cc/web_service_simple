#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'web_service/simple'
require 'tempfile'

describe WebService::Simple do
  it { WebService::Simple::VERSION.should =~ /\A\d+\.\d+\.\d+\Z/ }

  before do
    @base_url = 'http://api.example.com'
    @service = WebService::Simple.new(:base_url => @base_url)
  end

  describe 'を作成するとき' do
    it 'は、:base_url の値を @base_url に設定すること' do
      service = WebService::Simple.new(:base_url => @base_url)
      service.base_url.should == @base_url
    end

    it 'で、:base_url の値が未指定ならば ArgumentError が発生すること' do
      proc { WebService::Simple.new }.should raise_error(ArgumentError)
    end

    it 'は、:logger の値を @logger に設定すること' do
      logger = Logger.new(STDOUT)
      service = WebService::Simple.new(:base_url => @base_url, :logger => logger)
      service.logger.should == logger
    end

    it 'は、:debug の値を @debug に設定すること' do
      service = WebService::Simple.new(:base_url => @base_url, :debug => true)
      service.debug.should be_true
    end

    it 'は、:params の値を @basic_params に設定すること' do
      params = { :key => 'xxx' }
      service = WebService::Simple.new(:base_url => @base_url, :params => params)
      service.basic_params.should == params
    end

    it 'は、:param の値を @basic_params に設定すること' do
      param = { :key => 'xxx' }
      service = WebService::Simple.new(:base_url => @base_url, :param => param)
      service.basic_params.should == param
    end

    it 'は、:response_parser の値を @response_parer に設定すること' do
      service = WebService::Simple.new(:base_url => @base_url, :response_parser => 'XML::Nokogiri')
      service.response_parser.should_not be_nil

      service = WebService::Simple.new(:base_url => @base_url, :response_parser => { :module => 'XML::Nokogiri' })
      service.response_parser.should_not be_nil

      parser = WebService::Simple::Parser::XML::Nokogiri.new
      service = WebService::Simple.new(:base_url => @base_url, :response_parser => parser)
      service.response_parser.should_not be_nil
    end

    it 'で、:response_parser の値が未指定ならば @@config の値から @response_parser を設定すること' do
      service = WebService::Simple.new(:base_url => @base_url)
      service.response_parser.class.should == WebService::Simple::Parser::XML::Nokogiri
    end
  end

  describe '#logger' do
    it 'は、@logger を返すこと' do
      logger = Logger.new(StringIO.new)
      @service.logger = logger
      @service.logger.should == logger
    end

    it 'は、@logger が nil ならば標準出力 INFO レベルの Logger を返すこと' do
      logger = @service.logger
      logger.class.should == Logger
      logger.level.should == Logger::INFO
    end
  end

  describe '#response_parser' do
    it 'は、@response_parser が文字列ならば、そのレスポンスパーサを生成して返すこと' do
      @service.response_parser = 'XML::Nokogiri'
      @service.response_parser.class.should == WebService::Simple::Parser::XML::Nokogiri
    end

    it 'は、@response_parser がハッシュならば、そのレスポンスパーサを生成して返すこと' do
      @service.response_parser = { :module => 'XML::Nokogiri' }
      @service.response_parser.class.should == WebService::Simple::Parser::XML::Nokogiri
    end

    it 'は、@response_parser が Parser オブジェクトならば、それを返すこと' do
      parser = WebService::Simple::Parser::XML::Nokogiri.new
      @service.response_parser = parser
      @service.response_parser.should == parser
    end
  end

  describe '#get' do
    before do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = false
    end

    before do
      @service = WebService::Simple.new(:base_url => 'http://api.example.com', :param => { :key => 'xxx' })
    end

    it 'は、GET リクエストを送信して、Response オブジェクトを返すこと' do
      FakeWeb.register_uri(:get, 'http://api.example.com?key=xxx', :body => 'ok')

      response = @service.get
      response.class.should == WebService::Simple::Response
      response.content.should == 'ok'
    end

    it 'は、リクエストの結果、レスポンスコードが 200 以外ならば、例外 ResponseCodeError が発生すること' do
      FakeWeb.register_uri(:get, 'http://api.example.com?key=xxx', :body => 'nf', :status => ['404', 'Not Found'])
      begin
        @service.get
      rescue => e
        e.class.should == WebService::Simple::ResponseCodeError
        e.response_code.should == '404'
        e.response_body.should == 'nf'
      end
    end

    it 'は、引数に応じて、よしなにリクエストすること' do
      FakeWeb.register_uri(:get, 'http://api.example.com?key=xxx&word=yyy', :body => 'ok1')
      FakeWeb.register_uri(:get, 'http://api.example.com/hage?key=xxx&word=yyy', :body => 'ok2')
      FakeWeb.register_uri(:get, 'http://api.example.com/hage?key=xxx', :body => 'ok3')

      @service.get(:word => 'yyy').content.should == 'ok1'
      @service.get('/hage', :word => 'yyy').content.should == 'ok2'
      @service.get('/hage').content.should == 'ok3'
      @service.get('/hage').content.should == 'ok3'

      service = WebService::Simple.new(:base_url => 'http://api.example.com/hage', :param => { :key => 'xxx' })
      service.get.content.should == 'ok3'
    end

    it 'は、デバッグモードではないならば、ログを出力しないこと' do
      io = StringIO.new
      logger = Logger.new(io)
      @service.logger = logger
      @service.debug = false

      io.string.should be_empty
    end

    describe 'で、デバッグモードのとき' do
      before do
        @io = StringIO.new
        @logger = Logger.new(@io)

        FakeWeb.register_uri(:get, @base_url, :body => 'ok')

        @service = WebService::Simple.new(:base_url => @base_url, :debug => true)
      end

      it 'は、logger に対して INFO レベルのログを出力すること' do
        @logger.level = Logger::INFO
        @service.logger = @logger
        @service.get

        @io.string.should =~ %r!#{ Regexp.escape(@base_url) }!
      end

      it 'は、logger が INFO より上のレベルに設定されていればログを出力しないこと' do
        @logger.level = Logger::WARN
        @service.logger = @logger
        @service.get

        @io.string.should be_empty
      end
    end
  end

  describe '#post' do
    before do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = false
    end

    before do
      @service = WebService::Simple.new(:base_url => 'http://api.example.com', :param => { :key => 'xxx' })
    end

    before do
      @io = StringIO.new
      @logger = Logger.new(@io)
    end

    it 'は、POST リクエストを送信して、Response オブジェクトを返すこと' do
      FakeWeb.register_uri(:post, 'http://api.example.com', :body => 'ok')

      response = @service.post
      response.class.should == WebService::Simple::Response
      response.content.should == 'ok'
    end

    it 'は、リクエストの結果、レスポンスコードが 200 以外ならば、例外 ResponseCodeError が発生すること' do
      FakeWeb.register_uri(:post, 'http://api.example.com', :body => 'nf', :status => ['404', 'Not Found'])
      begin
        @service.post
      rescue WebService::Simple::ResponseCodeError => e
        e.response_code.should == '404'
        e.response_body.should == 'nf'
      end
    end

    it 'は、引数に応じて、よしなにリクエストすること' do
      FakeWeb.register_uri(:post, 'http://api.example.com', :body => 'ok1')
      FakeWeb.register_uri(:post, 'http://api.example.com/hage', :body => 'ok2')

      @service.post(:word => 'yyy').content.should == 'ok1'
      @service.post('/hage', :word => 'yyy').content.should == 'ok2'
      @service.post('/hage').content.should == 'ok2'
    end

    it 'は、デバッグモードではないならば、ログを出力しないこと' do
      @service.logger = @logger
      @service.debug = false
      @io.string.should be_empty
    end

    describe 'で、デバッグモードのとき' do
      before do
        FakeWeb.register_uri(:post, @base_url, :body => 'ok')
        @service = WebService::Simple.new(:base_url => @base_url, :debug => true)
      end

      it 'は、logger に対して INFO レベルのログを出力すること' do
        @logger.level = Logger::INFO
        @service.logger = @logger
        @service.post

        @io.string.should =~ %r!#{ Regexp.escape(@base_url) }!
      end

      it 'は、logger が INFO より上のレベルに設定されていればログを出力しないこと' do
        @logger.level = Logger::WARN
        @service.logger = @logger
        @service.post

        @io.string.should be_empty
      end
    end
  end
end

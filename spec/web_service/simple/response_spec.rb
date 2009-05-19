#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require 'web_service/simple/response'
require 'web_service/simple/parser'
require 'web_service/simple/parser/json'

describe WebService::Simple::Response do
  before do
    @parser = WebService::Simple::Parser::JSON.new
    @content = '{ error: 1 }'
    @response = WebService::Simple::Response.new(@content, @parser)
  end

  describe 'を作成するとき' do
    it 'は、第 1 引数を @content に、第 2 引数を @parser に設定すること' do
      @response.content.should == @content
    end
  end

  describe '#parse_response' do
    it 'は、パーサの parse_response メソッドを、自身を引数として呼び出すこと' do
      @parser.should_receive(:parse_response).with(@response)
      @response.parse_response
    end
  end
end

#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.expand_path('../../../../spec_helper', File.dirname(__FILE__))
require 'web_service/simple/parser'
require 'web_service/simple/parser/json/pure'

describe WebService::Simple::Parser::JSON::Pure do
  describe '#parse_response' do
    it 'は、json pure で JSON 文字列をパースして、その結果を返すこと' do
      parser = WebService::Simple::Parser::JSON::Pure.new
      response = stub(:response, :content => '{ "hoge": 3, "fuga": ["a", "b"] }')
      parser.parse_response(response).should == { 'hoge' => 3, 'fuga' => ['a', 'b'] }
    end
  end
end

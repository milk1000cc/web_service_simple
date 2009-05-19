#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require File.expand_path('../../../../spec_helper', File.dirname(__FILE__))
require 'web_service/simple/parser'
require 'web_service/simple/parser/xml/nokogiri'

describe WebService::Simple::Parser::XML::Nokogiri do
  before do
    @xml = <<-'EOF'
      <?xml version="1.0" encoding="UTF-8"?>
      <!-- generator="Technorati API version 1.0" -->
      <!DOCTYPE tapi PUBLIC "-//Technorati, Inc.//DTD TAPI 0.02//EN" "http://api.technorati.com/dtd/tapi-002.xml">
      <tapi version="1.0">
      <document>
        <result>
          <query>ミッドナイトクラブ</query>
          <total>109</total>
          <start/>
        </result>
      </document>
      </tapi>
    EOF
  end

  describe '#parse_response' do
    it 'は、nokogiri で xml をパースして、その結果を返すこと' do
      parser = WebService::Simple::Parser::XML::Nokogiri.new
      response = stub(:response, :content => @xml)
      parser.parse_response(response).at('//tapi/document/result/query').text.should == 'ミッドナイトクラブ'
    end
  end
end

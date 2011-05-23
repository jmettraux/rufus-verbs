
require File.dirname(__FILE__) + '/base.rb'

class PlainText
  
  def self.parse text
    self.new text
  end
  
  def initialize text
    @text = text
  end
  
end

class ParseTest < Test::Unit::TestCase
  include TestBaseMixin
  include Rufus::Verbs
  
  # def test_0
  #   ep = EndPoint.new(
  #     :host => "localhost", 
  #     :port => 7777,
  #     :headers => {'Accept' => 'text/plain'})
  #     
  #   ep.parsers['text/plain'] = PlainText
  #   
  #   resp = ep.get(:resource => "items")
  #   
  #   assert_equal 'text/plain', resp.header['content-type']
  #   assert_equal PlainText, resp.body.class
  #       
  # end
  
  def test_1
    require 'nokogiri'
    
    ep = EndPoint.new(:host => 'rufus.rubyforge.org')
    ep.parsers['text/html'] = Nokogiri::HTML::Document
    
    res = ep.get
    
    assert_equal Nokogiri::HTML::Document, res.body.class
    
  end  
  
end
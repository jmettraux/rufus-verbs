
#
# spec'ing rufus-verbs
#
# Sun Aug  4 18:56:08 JST 2013
#

require 'spec_helper'


describe Rufus::Verbs::EndPoint do

  #before(:each) do
  #  start_test_server
  #end
  #after(:each) do
  #  stop_test_server
  #end

  describe '.parsers' do

    #class PlainText
    #  def self.parse text
    #    self.new text
    #  end
    #  def initialize text
    #    @text = text
    #  end
    #end
    #
    #def test_0
    #  ep = EndPoint.new(
    #    :host => "localhost",
    #    :port => 7777,
    #    :headers => {'Accept' => 'text/plain'})
    #
    #  ep.parsers['text/plain'] = PlainText
    #
    #  resp = ep.get(:resource => "items")
    #
    #  assert_equal 'text/plain', resp.header['content-type']
    #  assert_equal PlainText, resp.body.class
    #
    #end

    it 'gives access to the content_type/parsers hash' do

      require 'nokogiri'

      ep = Rufus::Verbs::EndPoint.new(:host => 'rufus.rubyforge.org')
      ep.parsers['text/html'] = Nokogiri::HTML::Document

      res = ep.get

      res.body.class.should == Nokogiri::HTML::Document
    end
  end
end


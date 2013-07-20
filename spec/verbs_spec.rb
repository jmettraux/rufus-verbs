
#
# spec'ing rufus-verbs
#
# Sat Jul 20 22:32:42 JST 2013
#

require 'spec_helper'


describe Rufus::Verbs do

  before(:each) do
    start_test_server
  end
  after(:each) do
    stop_test_server
  end

  describe '.get' do

    it 'works' do

      r = Rufus::Verbs.get(:uri => "http://localhost:7777/items")

      r.class.should == Net::HTTPOK
    end
  end
end


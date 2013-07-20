
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

    it 'accepts the URI directly' do

      r = Rufus::Verbs.get('http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r.headers['content-length'].should == '3'
    end

    it 'accepts the URI via the :uri option' do

      r = Rufus::Verbs.get(:uri => 'http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r.headers['content-length'].should == '3'
    end

    it 'accepts the URI via the :u option' do

      r = Rufus::Verbs.get(:u => 'http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r.headers['content-length'].should == '3'
    end
  end
end


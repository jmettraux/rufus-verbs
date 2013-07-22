
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
      r['Content-Length'].should == '3'
    end

    it 'accepts the URI via the :uri option' do

      r = Rufus::Verbs.get(:uri => 'http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r['Content-Length'].should == '3'
    end

    it 'accepts the URI via the :u option' do

      r = Rufus::Verbs.get(:u => 'http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r['Content-Length'].should == '3'
    end

    it 'accepts a :host/:port/:path combination' do

      r = Rufus::Verbs.get(
        :host => 'localhost', :port => 7777, :path => '/items')

      r.code.should == '200'
      r.body.should == "{}\n"
      r['Content-Length'].should == '3'
    end

    it 'is ok with a URI without a path' do

      r = Rufus::Verbs.get('http://rufus.rubyforge.org')

      r.class.should == Net::HTTPOK
    end

    context ':body => true' do

      it 'returns the body directly (not the HTTPResponse)' do

        r = Rufus::Verbs.get('http://localhost:7777/items', :body => true)

        r.should == "{}\n"
      end
    end
  end

  describe '.post' do

    it 'posts data to a URI' do

      r = Rufus::Verbs.post('http://localhost:7777/items', :d => 'Toto')

      r.code.should == '201'
      r['Location'].should == 'http://localhost:7777/items/0'

      r = Rufus::Verbs.get('http://localhost:7777/items/0')
      r.body.should == "\"Toto\"\n"
    end

    it 'accepts a block returning the data to post' do

      r =
        Rufus::Verbs.post('http://localhost:7777/items') do
          "nada" * 3
        end

      r.code.should == '201'
      r['Location'].should == 'http://localhost:7777/items/0'

      r = Rufus::Verbs.get('http://localhost:7777/items/0')
      r.body.should == "\"nadanadanada\"\n"
    end
  end

  describe '.put' do

    before(:each) do
      Rufus::Verbs.post('http://localhost:7777/items', :d => 'Toto')
    end

    it 'puts data to a URI' do

      r = Rufus::Verbs.put('http://localhost:7777/items/0', :d => 'Toto2')

      r.code.should == '200'

      r = Rufus::Verbs.get('http://localhost:7777/items/0')
      r.body.should == "\"Toto2\"\n"
    end

    it 'accepts a block returning the data to put' do

      r =
        Rufus::Verbs.put('http://localhost:7777/items/0') do
          'xxx'
        end

      r.code.should == '200'

      r = Rufus::Verbs.get('http://localhost:7777/items/0')
      r.body.should == "\"xxx\"\n"
    end

    context ':fake_put => true' do

      it 'uses POST behind the scenes' do

        r = Rufus::Verbs.put(
          'http://localhost:7777/items/0', :fake_put => true, :d => 'Maurice')

        r.code.should == '200'

        r = Rufus::Verbs.get('http://localhost:7777/items')
        r.body.should == "{0=>\"Maurice\"}\n"
      end
    end
  end

  describe '.head' do

    it 'behaves like .get but does not fetch the body' do

      r = Rufus::Verbs.head('http://localhost:7777/items')

      r.code.should == '200'
      r.body.should == nil
    end
  end
end


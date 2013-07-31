
#
# spec'ing rufus-verbs
#
# Wed Jul 31 20:36:26 JST 2013
#

require 'spec_helper'


describe Rufus::Verbs do

  U = 'http://rufus.rubyforge.org/'

  def acquire_proxy

    proxies =
      Rufus::Verbs.get(
        'http://freeproxy.ch/proxy.txt'
      ).body.lines.to_a.collect { |l|
        l.split("\t").first
      }.select { |l|
        l.match(/^[\d\.]+:\d+$/)
      }.collect { |l|
        "http://#{l}"
      }

    res = nil

    proxy =
      proxies.find do |xy|
        begin
          Timeout::timeout(2) { res = Rufus::Verbs.get(U, :proxy => xy) }
          res.code.to_i == 200
        rescue => e
          false
        end
      end

    proxy
  end

  before(:all) do

    @proxy = acquire_proxy
  end

  context ':proxy => http://proxy.example.com' do

    it 'works' do

      res0 = Rufus::Verbs.get(U)
      res1 = Rufus::Verbs.get(U, :proxy => @proxy)

      res1.body.should == res0.body

      res0['via'].should == nil
      res1['via'].should_not == nil
    end
  end
end


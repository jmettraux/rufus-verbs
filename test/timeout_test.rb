
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Mon May 26 17:04:25 JST 2008
#

require 'rubygems'

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class TimeoutTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        error = nil
        t = Time.now

        begin
            get :uri => "http://localhost:7777/lost", :to => 1
        rescue Timeout::Error => e
            error = e
        end

        assert_not_nil error
        assert (Time.now - t < 2)
    end
end

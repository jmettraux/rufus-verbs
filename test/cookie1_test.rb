
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Sun Jan 13 12:33:03 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class Cookie1Test < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        ep = EndPoint.new :cookies => true
        class << ep
            attr_reader :cookies
        end

        assert_equal 0, ep.cookies.size

        ep.get :uri => "http://localhost:7777/cookie"
        assert_equal 1, ep.cookies.size

        req = ep.get :uri => "http://localhost:7777/cookie", :dry_run => true
        assert_match /^tcookie=\d*$/, req['Cookie']
    end

    def test_1

        ep0 = EndPoint.new :cookies => true
        ep1 = EndPoint.new :cookies => true

        ep0.post("http://localhost:7777/cookie") { "smurf0" }
        ep1.post("http://localhost:7777/cookie") { "smurf1" }

        expect 200, [ 'smurf0' ], ep0.get("http://localhost:7777/cookie")
        expect 200, [ 'smurf1' ], ep1.get("http://localhost:7777/cookie")
    end

    def test_2

        ep = EndPoint.new :cookies => false # explicitely

        res0 = ep.post("http://localhost:7777/cookie") { "smurf0" }
        res1 = expect 200, [], ep.get("http://localhost:7777/cookie")

        assert_not_equal res0['Set-Cookie'], res1['Set-Cookie']
    end
end



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


class Auth1Test < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs

    #
    # Using an items server with the authentication on.
    #
    def setup

        @server = ItemServer.new :auth => :digest
        @server.start
    end


    def test_0

        #res = get :uri => "http://localhost:7777/items"
        #assert_equal 200, res.code.to_i
        #assert_equal "{}", res.body.strip
        #res = expect 401, nil, get(:uri => "http://localhost:7777/items")
        #p res['www-authenticate']

        #$DEBUG = true

        ep = EndPoint.new :digest_authentication => [ "test", "pass" ]

        expect 200, {}, ep.get("http://localhost:7777/items")
        assert_equal 2, $dcount

        expect 200, {}, ep.get("http://localhost:7777/items")
        assert_equal 3, $dcount

        expect 201, nil, ep.post("http://localhost:7777/items/1") { "hammer" }
        assert_equal 4, $dcount

        expect 200, { 1 => "hammer" }, ep.get("http://localhost:7777/items")
        assert_equal 5, $dcount

        expect 401, nil, get(:uri => "http://localhost:7777/items")
        assert_equal 6, $dcount

        expect 401, nil, get(
            :uri => "http://localhost:7777/items", 
            :http_basic_authentication => [ "toto", "toto" ])
        assert_equal 7, $dcount

        expect 200, { 1 => "hammer" }, get(
            :uri => "http://localhost:7777/items", 
            :digest_authentication => [ "test", "pass" ])
        assert_equal 9, $dcount
    end
end

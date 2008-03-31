
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


class Auth0Test < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs

    #
    # Using an items server with the authentication on.
    #
    def setup

        @server = ItemServer.new :auth => :basic
        @server.start
    end


    def test_0

        #res = get :uri => "http://localhost:7777/items"
        #assert_equal 200, res.code.to_i
        #assert_equal "{}", res.body.strip
        expect 401, nil, get(:uri => "http://localhost:7777/items")

        expect 401, nil, get(
            :uri => "http://localhost:7777/items", 
            :http_basic_authentication => [ "toto", "wrong" ])

        expect 200, {}, get(
            :uri => "http://localhost:7777/items?a", 
            :http_basic_authentication => [ "toto", "toto" ])
    end
end

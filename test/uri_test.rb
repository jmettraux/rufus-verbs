
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Mon Feb 18 11:05:07 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class UriTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs

    def test_0

        uri = URI.parse "http://localhost:7777/items"

        res = get :uri => uri
        assert_equal 200, res.code.to_i
        assert_equal "{}", res.body.strip

        res = get uri
        assert_equal 200, res.code.to_i
        assert_equal "{}", res.body.strip
    end
end

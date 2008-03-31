
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Sun Jan 13 20:02:25 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class RedirTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        expect 200, {}, get(:uri => "http://localhost:7777/things")
    end

    #
    # testing the :no_redirections directive
    #
    def test_1

        res = get "http://localhost:7777/things", :no_redirections => true
        assert_equal 303, res.code.to_i

        res = get("http://localhost:7777/things", :noredir => true)
        assert_equal 303, res.code.to_i

        expect 200, {}, get("http://localhost:7777/items", :noredir => true)
    end
end


#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Tue Feb 12 23:10:54 JST 2008
#

require 'test/unit'

require 'rufus/verbs'


class EscapeTest < Test::Unit::TestCase

    include Rufus::Verbs


    def test_0

        req = put(
            :dry_run => true, 
            :uri => "http://localhost:7777/items/1", 
            :query => { "a" => "hontou ni ?" })

        assert_equal "/items/1?a=hontou%20ni%20?", req.path

        req = put(
            :dry_run => true, 
            :uri => "http://localhost:7777/items/1", 
            :params => { "a" => "hontou ni ?" },
            :no_escape => true)

        assert_equal "/items/1?a=hontou ni ?", req.path
            # would fail anyway...
    end
end

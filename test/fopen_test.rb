
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Mon Feb 18 13:00:36 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class UriTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs

    def test_0

        uri = "http://localhost:7777/items"

        res = fopen uri
        assert_equal 200, res.code.to_i
        assert_equal "{}", res.body.strip

        res = fopen "file:CHANGELOG.txt"
        assert_kind_of String, res.read

        res = fopen "CHANGELOG.txt"
        assert_kind_of String, res.read

        res = fopen "http://localhost:7777/things"
        assert_equal 200, res.code.to_i
        assert_equal "{}", res.body.strip
            #
            # it follows redirections :)

        res = fopen "http://localhost:7777/things", :noredir => true
        assert_equal 303, res.code.to_i

        fopen "CHANGELOG.txt" do |f|
            assert_kind_of String, f.read
        end

        fopen "http://localhost:7777/things" do |res|
            assert_equal 200, res.code.to_i
            assert_equal "{}", res.body.strip
        end
    end

    def test_1

        assert_kind_of String, fopen("CHANGELOG.txt").read
        assert_kind_of String, fopen("file:CHANGELOG.txt").read
        assert_kind_of String, fopen("http://localhost:7777/items").read
    end
end

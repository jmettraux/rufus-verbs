
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Wed Jan 16 13:54:36 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class ConditionalTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_1

        ep = ConditionalEndPoint.new(:host => "localhost", :port => 7777)
        expect 200, {}, ep.get(:resource => "items")

        res = ep.put :resource => "items", :id => 0 do
            "blockdata"
        end
        assert_equal 404, res.code.to_i

        res = ep.post :resource => "items", :id => 0 do
            "blockdata"
        end
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/0", res['Location']

        res = expect 200, { 0 => "blockdata" }, ep.get(:res => "items")
        assert_kind_of Net::HTTPResponse, res
        assert_respond_to res, :lastmod
        i = res.object_id
        #p res.to_hash

        res = expect 200, { 0 => "blockdata" }, ep.get(:res => "items")
        assert_equal i, res.object_id

        assert_equal 1, ep.cache_current_size
    end
end

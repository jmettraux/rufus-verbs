
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


class ItemConditionalTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        require 'open-uri'
        f = open "http://localhost:7777/items"
        d = f.read
        f.close

        assert_equal "{}", d.strip
    end

    def test_1

        res = get :uri => "http://localhost:7777/items"

        assert_equal 200, res.code.to_i
        assert_equal "{}", res.body.strip

        p res['Etag']
        #p res['Last-Modified']
        assert res['Etag'].length > 0
        assert res['Last-Modified'].length > 0
    end

    def test_2

        res = get "http://localhost:7777/items"
        assert_equal 200, res.code.to_i

        lm = res['Last-Modified']
        etag = res['Etag']

        res = get(
            "http://localhost:7777/items", 
            :headers => { 'If-Modified-Since' => lm })
        assert_equal 304, res.code.to_i

        res = get(
            "http://localhost:7777/items", :h => { 'If-None-Match' => etag })
        assert_equal 304, res.code.to_i

        res = get(
            "http://localhost:7777/items", 
            :h => { 'If-Modified-Since' => lm, 'If-None-Match' => etag })
        assert_equal 304, res.code.to_i
    end
end


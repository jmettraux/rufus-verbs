
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Sun Jan 13 12:33:03 JST 2008
#

require 'rubygems'

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class SimpleTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        #res = get :uri => "http://localhost:7777/items"
        #assert_equal 200, res.code.to_i
        #assert_equal "{}", res.body.strip
        expect 200, {}, get(:uri => "http://localhost:7777/items")

        res = post :uri => "http://localhost:7777/items/0", :d => "Toto"
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/0", res['Location']

        expect 200, { 0 => "Toto" }, get(:uri => "http://localhost:7777/items")

        res = get :host => "localhost", :port => 7777, :path => "/items"
        assert_equal 200, res.code.to_i
        assert_equal ({ 0 => "Toto" }), eval(res.body)

        res = put :uri => "http://localhost:7777/items/0", :d => "Toto2"
        assert_equal 200, res.code.to_i

        expect 200, { 0 => "Toto2" }, get(:uri => "http://localhost:7777/items")

        res = put :uri => "http://localhost:7777/items/0", :d => "Toto3", :fake_put => true
        assert_equal 200, res.code.to_i

        expect 200, { 0 => "Toto3" }, get(:uri => "http://localhost:7777/items")
    end

    def test_0b

        expect 200, {}, get(:uri => "http://localhost:7777/items")

        res = post :uri => "http://localhost:7777/items", :d => "Toto"
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/0", res['Location']

        expect 200, "\"Toto\"", get(:uri => "http://localhost:7777/items/0")

        res = post :uri => "http://localhost:7777/items", :d => "Smurf"
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/1", res['Location']

        expect 200, "\"Smurf\"", get(:uri => "http://localhost:7777/items/1")
    end

    def test_1

        ep = EndPoint.new(:host => "localhost", :port => 7777)
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

        expect 200, { 0 => "blockdata" }, ep.get(:res => "items")
    end

    def test_2

        s = get(:uri => "http://localhost:7777/items", :body => true)
        assert_equal "{}", s.strip
    end

    #
    # The "no-path" test
    #
    def test_3

        r = get "http://rufus.rubyforge.org"
        assert_kind_of Net::HTTPOK, r
    end

    #
    # HEAD
    #
    def test_4

        res = head "http://localhost:7777/items"
        assert_equal 200, res.code.to_i
        assert_nil res.body
    end

    #
    # OPTIONS
    #
    def test_5

        r = options "http://localhost:7777/items"
        assert_equal [ :delete, :get, :head, :options, :post, :put], r
    end

    def test_6

        r = Rufus::Verbs::options "http://localhost:7777/items"
        assert_equal [ :delete, :get, :head, :options, :post, :put], r
    end
end

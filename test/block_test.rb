
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


class BlockTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs


    def test_0

        res = post :uri => "http://localhost:7777/items/0" do
            "Fedor" +
            "Fedorovitch"
        end
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/0", res['Location']


        expect(
            200, 
            { 0 => "FedorFedorovitch" }, 
            get(:uri => "http://localhost:7777/things"))

        res = post :uri => "http://localhost:7777/items/1" do |req|
            # do whatever with the request [headers]
            "John"
        end
        assert_equal 201, res.code.to_i
        assert_equal "http://localhost:7777/items/1", res['Location']

        expect(
            200, 
            { 0 => "FedorFedorovitch", 1 => "John" }, 
            get(:uri => "http://localhost:7777/things"))
    end
end

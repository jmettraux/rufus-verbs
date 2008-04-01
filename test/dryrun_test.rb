
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Tue Jan 15 09:26:45 JST 2008
#

require 'test/unit'

require 'rufus/verbs'


class DryRunTest < Test::Unit::TestCase

    include Rufus::Verbs


    def test_0

        req = put(
            :dry_run => true, 
            :uri => "http://localhost:7777/items/1", 
            :params => { "a" => "A", :b => :B })

        assert_equal "/items/1?a=A&b=B", req.path

        req = post(
            :dry_run => true, 
            :uri => "http://localhost:7777/items/1", 
            :params => { "a" => "A", :b => :B })

        assert_equal "/items/1?a=A&b=B", req.path

        req = put(
            :dry_run => true, 
            :uri => "http://localhost:7777/items/1", 
            :query => { "a" => "A", :b => :B })

        assert_equal "/items/1?a=A&b=B", req.path

        req = put(
            "http://localhost:7777/items/1?a=A", :d => "toto", :dry_run => true)

        assert_equal "/items/1?a=A", req.path
        assert_equal "toto", req.body
    end

    def test_1

        ep = Rufus::Verbs::EndPoint.new(
            :host => 'localhost',
            :resource => 'whatever')

        req = ep.get(
            :dry_run => true,
            :resource => 'other',
            :params => { 'a' => 'A', 'b' => 'B' })

        assert_equal "/other?a=A&b=B", req.path

        req = ep.post(
            :dry_run => true,
            :resource => 'other',
            :query => { 'a' => 'A', 'b' => 'B' })
        
        assert_equal "/other?a=A&b=B", req.path
    end
end

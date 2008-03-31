
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Mon Jan 14 00:07:38 JST 2008
#

require 'test/unit'
require 'testbase'

require 'rufus/verbs'


class HttpsTest < Test::Unit::TestCase
    include TestBaseMixin

    include Rufus::Verbs

    def setup
        # no need for an items server
    end

    def teardown
    end

    def test_0

        res = expect(
            200, 
            nil, 
            get(:uri => "http://jmettraux.wordpress.com/2006/03/31/cvs-down/"))

        #res.each_header do |h|
        #    p h
        #end

        #puts res.body
        assert res.body.match "^<!DOCTYPE html PUBLIC"
    end
end


#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Thu Jan 17 10:15:52 JST 2008
#

require 'timeout'
require 'test/unit'

require 'rufus/verbs'


class ProxyTest < Test::Unit::TestCase

    include Rufus::Verbs


    def test_0

        uri = "http://rufus.rubyforge.org/rufus-verbs/index.html"

        res0 = get(uri, :proxy => false)

        assert_not_nil res0.body # just displaying the test dot

        proxies = find_proxies

        res1 = nil

        proxies.each do |proxy|
            begin
                Timeout::timeout 2 do
                    res1 = get(uri, :proxy => proxy)
                end
                break if res1.code.to_i == 200
            rescue Exception => e
                puts "skipped proxy '#{proxy}'"
            end
        end

        if res1.code.to_i != 200
            puts
            puts
            puts "sorry, couldn't find an open proxy, couldn't test the"
            puts "proxy feature of 'rufus-verbs'"
            puts
            puts
            return
        end

        assert_equal res0.body.length, res1.body.length

        #p res0.to_hash
        #p res1.to_hash

        via1 = res1["via"]

        unless via1
            puts
            puts
            puts "seems like no open proxy could be found... no via..."
            puts "can't test for now"
            puts
            puts
            return
        end

        via1 = res1["via"].split(", ")[-1]
            # last proxy

        assert_no_match /wikimedia\.org/, via1
            # making sure that the proxy was not one of wikipedia
    end

    protected

        def find_proxies

            res = get "http://freeproxy.ch/proxy.txt"
            lines = res.body.split "\n"
            lines[4..-1].collect do |line|
                l = line.split("\t")
                'http://' + l[0]
            end
        end

end


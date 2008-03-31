
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Sun Jan 13 18:02:50 JST 2008
#

require 'items'


module TestBaseMixin

    def setup

        @server = ItemServer.new
        @server.start
    end

    def teardown

        @server.shutdown
    end

    protected

        #
        # one or two asserts...
        #
        def expect (code, res_body, res)

            assert_equal code, res.code.to_i

            val = res.body

            val = if res_body.is_a?(String)
                val.strip
            elsif res_body
                eval(val)
            end

            assert_equal(res_body, val) if res_body

            res
        end
end

#
#--
# Copyright (c) 2008, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# (MIT license)
#++
#

#
# John Mettraux
#
# Made in Japan
#
# 2008/03/31
#

module Rufus
module Verbs

    #
    # Methods for the verbose mode
    #
    module VerboseMixin

        protected

            #
            # logs a unique message to the verbose channel (if any).
            #
            def vlog (opts, msg)

                channel = get_channel(opts) or return

                channel << msg
            end

            #
            # logs the outgoing request
            #
            def vlog_request (opts, req)

                channel = get_channel(opts) or return

                channel << "> #{req.method} #{req.path}\n"

                req.each do |k, v|
                    channel << "> #{k}: #{v}\n"
                end

                channel << ">\n"
            end

            def vlog_http (opts, http)

                channel = get_channel(opts) or return

                channel << "* #{http.address}:#{http.port}\n"
                channel << "*\n"
            end

            #
            # logs the incoming response
            #
            def vlog_response (opts, res)

                channel = get_channel(opts) or return

                channel << "< #{res.code} #{res.message}\n"
                channel << "<\n"

                res.each do |k, v|
                    channel << "< #{k}: #{v}\n"
                end

                channel << "<\n"
            end

        private

            def get_channel (opts)

                v = o(opts, [ :verbose, :v ])

                return nil if (not v) or (v.to_s == 'false')

                v = $stdout if v.to_s == 'true'

                return nil unless v.is_a?(IO)

                v
            end
    end

end
end


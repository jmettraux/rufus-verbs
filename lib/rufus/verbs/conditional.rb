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
# 2008/01/16
#

#require 'rubygems'
require 'rufus/lru'


module Rufus::Verbs

    #
    # An EndPoint with a cache for conditional GETs.
    #
    #     ep = ConditionalEndPoint.new(
    #         :host => "restful.server", 
    #         :port => 7080, 
    #         :resource => "inventory/tools")
    #
    #     res = ep.get :id => 1
    #         # first call will retrieve the representation completely
    #
    #     res = ep.get :id => 1
    #         # the server (provided that it supports conditional GET) only 
    #         # returned a 304 answer, the response is returned from the
    #         # ConditionalEndPoint cache
    #
    # The :cache_size option allows to set the size of the conditional GET
    # cache. The default size is currently 147.
    #
    class ConditionalEndPoint < EndPoint

        def initialize (opts)

            super

            cs = opts[:cache_size] || 147

            @cache = LruHash.new cs
        end

        #
        # Returns the count of representation 'cached' here for the
        # purpose of conditional GET requests.
        #
        def cache_current_size

            @cache.size
        end

        #
        # Returns the max size of the conditional GET cache.
        #
        def cache_size

            @cache.maxsize
        end

        private

            #
            # If the representation has already been gotten, send
            # potential If-Modified-Since and/or If-None-Match.
            #
            def add_conditional_headers (req, opts)

                # if path is cached send since and/or match

                e = @cache[opts[:c_uri]]

                return unless e # not cached

                req['If-Modified-Since'] = e.lastmod if e.lastmod
                req['If-None-Match'] = e.etag if e.etag

                opts[:c_cached] = e
            end

            def handle_response (method, res, opts)

                # if method is get and reply is 200, cache (if et and/or lm)
                # if method is get and reply is 304, return from cache

                super

                code = res.code.to_i

                return opts[:c_cached] if code == 304

                cache(res, opts) if code == 200

                res
            end

            def cache (res, opts)

                class << res
                    def lastmod
                        self['Last-Modified']
                    end
                    def etag
                        self['Etag']
                    end
                end

                @cache[opts[:c_uri]] = res
            end
    end
end


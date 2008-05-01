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
# 2008/01/19
#

require 'webrick/cookie'

#require 'rubygems'
require 'rufus/lru'


module Rufus
module Verbs

    #
    # Cookies related methods
    #
    # http://www.ietf.org/rfc/rfc2109.txt
    #
    module CookieMixin

        #
        # making the cookie jar available
        #
        attr_reader :cookies

        protected

            #
            # Prepares the instance variable @cookies for storing
            # cooking for this endpoint.
            #
            # Reads the :cookies endpoint option for determining the
            # size of the cookie jar (77 by default).
            #
            def prepare_cookie_jar

                o = @opts[:cookies]

                return unless o and o != false

                s = o.to_s.to_i
                s = 77 if s < 1

                @cookies = CookieJar.new s
            end

            #
            # Parses the HTTP response for a potential 'Set-Cookie' header,
            # parses and returns it as a hash.
            #
            def parse_cookies (response)

                c = response['Set-Cookie']
                return nil unless c
                Cookie.parse_set_cookies c
            end

            #
            # (This method will have no effect if the EndPoint is not
            # tracking cookies)
            #
            # Registers a potential cookie set by the server.
            #
            def register_cookies (response, opts)

                return unless @cookies

                cs = parse_cookies response

                return unless cs

                # "The origin server effectively ends a session by
                #  sending the client a Set-Cookie header with Max-Age=0"

                cs.each do |c|

                    host = opts[:host]
                    path = opts[:path]
                    cpath = c.path || "/"

                    next unless cookie_acceptable?(opts, response, c)

                    domain = c.domain || host

                    if c.max_age == 0
                        @cookies.remove_cookie domain, path, c
                    else
                        @cookies.add_cookie domain, path, c
                    end
                end
            end

            #
            # Checks if the cookie is acceptable in the context of 
            # the request that sent it.
            #
            def cookie_acceptable? (opts, response, cookie)

                # reject if :
                #
                # * The value for the Path attribute is not a prefix of the 
                #   request-URI.
                # * The value for the Domain attribute contains no embedded dots
                #   or does not start with a dot.
                # * The value for the request-host does not domain-match the 
                #   Domain attribute.
                # * The request-host is a FQDN (not IP address) and has the form
                #   HD, where D is the value of the Domain attribute, and H is a
                #   string that contains one or more dots.

                cdomain = cookie.domain

                if cdomain

                    return false unless cdomain.index '.'
                    return false if cdomain[0, 1] != '.'

                    h, d = split_host(opts[:host])
                    return false if d != cdomain
                end

                #path = opts[:path]
                path = response.request.path

                cpath = cookie.path || "/"

                return false if path[0..cpath.length-1] != cpath

                true
            end

            # 
            # Places the 'Cookie' header in the request if appropriate.
            #
            # (This method will have no effect if the EndPoint is not
            # tracking cookies)
            #
            def mention_cookies (request, opts)

                return unless @cookies

                cs = @cookies.fetch_cookies opts[:host], opts[:path]

                request['Cookie'] = cs.collect { |c| c.to_header_s }.join(",")
            end
    end

    #
    # An extension of the cookie implementation found in WEBrick.
    #
    # Unmodified for now.
    #
    class Cookie < WEBrick::Cookie

        def to_header_s

            ret = ""
            ret << @name << "=" << @value
            ret << "; " << "$Version=" << @version.to_s if @version > 0
            ret << "; " << "$Domain="  << @domain  if @domain
            ret << "; " << "$Port="    << @port if @port
            ret << "; " << "$Path="    << @path if @path
            ret
        end
    end

    #
    # Cookies are stored by domain, they via this CookieKey which gathers
    # path and name of the cookie.
    #
    class CookieKey

        attr_reader :name, :path

        def initialize (path, cookie)

            @name = cookie.name
            @path = path || cookie.path
        end

        #
        # longer paths first
        #
        def <=> (other)

            -1 * (@path <=> other.path)
        end

        def hash
            "#{@name}|#{@path}".hash
        end

        def == (other)
            (@path == other.path and @name == other.name)
        end

        alias eql? ==
    end

    #
    # A few methods about hostnames.
    #
    # (in a mixin... could be helpful somewhere else later)
    #
    module HostMixin

        #
        # Matching a classical IP address (not a v6 though).
        # Should be sufficient for now.
        #
        IP_REGEX = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/

        #
        # Returns a pair host/domain, note that the domain starts with a dot.
        #
        #     split_host('localhost') --> [ 'localhost', nil ]
        #     split_host('benz.car.co.nz') --> [ 'benz', '.car.co.nz' ]
        #     split_host('127.0.0.1') --> [ '127.0.0.1', nil ]
        #     split_host('::1') --> [ '::1', nil ] 
        #
        def split_host (host)

            return [ host, nil ] if IP_REGEX.match host
            i = host.index('.')
            return [ host, nil ] unless i
            [ host[0..i-1], host[i..-1] ]
        end
    end

    #
    # The container for cookies. Features methods for storing and retrieving
    # cookies easily.
    #
    class CookieJar
        include HostMixin

        def initialize (jar_size)

            @per_domain = LruHash.new jar_size
        end

        #
        # Returns the count of cookies currently stored in this jar.
        #
        def size

            @per_domain.keys.inject(0) { |i, d| i + @per_domain[d].size }
        end

        def add_cookie (domain, path, cookie)

            (@per_domain[domain] ||= {})[CookieKey.new(path, cookie)] = cookie
        end

        def remove_cookie (domain, path, cookie)

            (d = @per_domain[domain])
            return unless d
            d.delete CookieKey.new(path, cookie)
        end

        #
        # Retrieves the cookies that matches the combination host/path.
        # If the retrieved cookie is expired, will remove it from the jar
        # and return nil.
        #
        def fetch_cookies (host, path)

            c = do_fetch(@per_domain[host], path)

            h, d = split_host host
            c += do_fetch(@per_domain[d], path) if d

            c
        end

        private

            #
            # Returns all the cookies that match a domain (host) and a path.
            #
            def do_fetch (dh, path)

                return [] unless dh

                keys = dh.keys.sort.find_all do |k|
                    path[0..k.path.length-1] == k.path
                end
                keys.inject([]) do |r, k|
                    r << dh[k]
                    r
                end
            end
    end
end
end


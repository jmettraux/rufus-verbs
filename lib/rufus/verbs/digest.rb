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
# 2008/01/21
#

require 'digest/md5'


module Rufus
module Verbs

    #
    # Specified by http://www.ietf.org/rfc/rfc2617.txt
    # Inspired by http://segment7.net/projects/ruby/snippets/digest_auth.rb
    #
    # The EndPoint classes mixes this in to support digest authentication.
    #
    module DigestAuthMixin

        #
        # Makes sure digest_auth is on
        #
        def digest_auth (req, opts)

            #return if no_digest_auth
                # already done in add_authentication()

            @cnonce ||= generate_cnonce
            @nonce_count ||= 0

            mention_digest_auth(req, opts) \
                and return

            mention_digest_auth(req, opts) \
                if request_challenge(req, opts)
        end

        #
        # Sets the 'Authorization' header with the appropriate info.
        #
        def mention_digest_auth (req, opts)

            return false unless @challenge

            req['Authorization'] = generate_header req, opts

            true
        end

        #
        # Interprets the information in the response's 'Authorization-Info'
        # header.
        #
        def check_authentication_info (res, opts)

            return if no_digest_auth
                # not using digest authentication

            return unless @challenge
                # not yet authenticated

            authinfo = AuthInfo.new res
            @challenge.nonce = authinfo.nextnonce
        end

        protected

            #
            # Returns true if :digest_authentication is set at endpoint
            # or request level.
            #
            def no_digest_auth

                (not o(opts, :digest_authentication))
            end

            #
            # To be enhanced.
            #
            # (For example http://www.intertwingly.net/blog/1585.html)
            #
            def generate_cnonce

                Digest::MD5.hexdigest("%x" % (Time.now.to_i + rand(65535)))
            end

            def request_challenge (req, opts)

                op = opts.dup

                op[:digest_authentication] = false
                    # preventing an infinite loop

                method = req.class.const_get(:METHOD).downcase.to_sym
                #method = :get

                res = request(method, op)

                return false if res.code.to_i != 401

                @challenge = Challenge.new res

                true
            end

            #
            # Generates an MD5 digest of the arguments (joined by ":").
            #
            def h (*args)

                Digest::MD5.hexdigest(args.join(":"))
            end

            #
            # Generates the Authentication header that will be returned
            # to the server.
            #
            def generate_header (req, opts)

                @nonce_count += 1

                user, pass = o(opts, :digest_authentication)
                realm = @challenge.realm || ""
                method = req.class.const_get(:METHOD)
                path = opts[:path]

                a1 = if @challenge.algorithm == 'MD5-sess'
                    h(h(user, realm, pass), @challenge.nonce, @cnonce)
                else
                    h(user, realm, pass)
                end

                a2, qop = if @challenge.qop.include?("auth-int")
                    [ h(method, path, h(req.body)), "auth-int" ]
                else
                    [ h(method, path), "auth" ]
                end

                nc = ('%08x' % @nonce_count)

                digest = h(
                    #a1, @challenge.nonce, nc, @cnonce, @challenge.qop, a2)
                    a1, @challenge.nonce, nc, @cnonce, "auth", a2)

                header = ""
                header << "Digest username=\"#{user}\", "
                header << "realm=\"#{realm}\", "
                header << "qop=\"#{qop}\", "
                header << "uri=\"#{path}\", "
                header << "nonce=\"#{@challenge.nonce}\", "
                #header << "nc=##{nc}, "
                header << "nc=#{nc}, "
                header << "cnonce=\"#{@cnonce}\", "
                header << "algorithm=\"#{@challenge.algorithm}\", "
                #header << "algorithm=\"MD5-sess\", "
                header << "response=\"#{digest}\", "
                header << "opaque=\"#{@challenge.opaque}\""

                header
            end

            #
            # A common parent class for Challenge and AuthInfo.
            # Their header parsing code is here.
            #
            class ServerReply

                def initialize (res)

                    s = res[header_name]
                    return nil unless s

                    s = s[7..-1] if s[0, 6] == "Digest"

                    s = s.split ","

                    s.each do |e|

                        k, v = parse_entry e

                        if k == 'stale'
                            @stale = (v.downcase == 'true') 
                        elsif k == 'nc'
                            @nc = v.to_i
                        elsif k == 'qop'
                            @qop = v.split ","
                        else
                            instance_variable_set "@#{k}".to_sym, v
                        end
                    end
                end

                protected

                    def parse_entry (e)

                        k, v = e.split "=", 2
                        v = v[1..-2] if v[0, 1] == '"'
                        [ k.strip, v.strip ]
                    end
            end

            #
            # Used when parsing a 'www-authenticate' header challenge.
            #
            class Challenge < ServerReply

                attr_accessor \
                    :opaque, :algorithm, :qop, :stale, :nonce, :realm, :charset

                def header_name
                    'www-authenticate'
                end
            end

            #
            # Used when parsing a 'authentication-info' header info.
            #
            class AuthInfo < ServerReply

                attr_accessor \
                    :cnonce, :rspauth, :nextnonce, :qop, :nc

                def header_name
                    'authentication-info'
                end
            end
    end

end
end


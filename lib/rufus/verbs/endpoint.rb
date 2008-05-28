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
# 2008/01/11
#

require 'uri'
require 'yaml' # for StringIO (at least for now)
require 'net/http'
require 'zlib'

require 'rufus/verbs/version'
require 'rufus/verbs/cookies'
require 'rufus/verbs/digest'
require 'rufus/verbs/verbose'


module Rufus
module Verbs

    USER_AGENT = "Ruby rufus-verbs #{VERSION}"

    #
    # An EndPoint can be used to share common options among a set of
    # requests.
    #
    #     ep = EndPoint.new(
    #         :host => "restful.server",
    #         :port => 7080,
    #         :resource => "inventory/tools")
    #
    #     res = ep.get :id => 1
    #         # still a silver bullet ?
    #
    #     res = ep.get :id => 0
    #         # where did the hammer go ?
    #
    # When a request gets prepared, the option values will be looked up
    # in (1) its local (request) options, then (2) in the EndPoint options.
    #
    class EndPoint

        include CookieMixin
        include DigestAuthMixin
        include VerboseMixin

        #
        # The endpoint initialization opts (Hash instance)
        #
        attr_reader :opts

        def initialize (opts)

            @opts = opts

            compute_target @opts

            @opts[:http_basic_authentication] =
                opts[:http_basic_authentication] || opts[:hba]

            @opts[:user_agent] ||= USER_AGENT

            @opts[:proxy] ||= ENV['HTTP_PROXY']

            prepare_cookie_jar
        end

        def get (*args)

            request :get, args
        end

        def post (*args, &block)

            request :post, args, &block
        end

        def put (*args, &block)

            request :put, args, &block
        end

        def delete (*args)

            request :delete, args
        end

        def head (*args)

            request :head, args
        end

        def options (*args)

            request :options, args
        end

        #
        # This is the method called by the module methods verbs.
        #
        # For example,
        #
        #     RufusVerbs.get(args)
        #
        # calls
        #
        #     RufusVerbs::EndPoint.request(:get, args)
        #
        def self.request (method, args, &block)

            opts = extract_opts args

            EndPoint.new(opts).request(method, opts, &block)
        end

        #
        # The instance methods get, post, put and delete ultimately calls
        # this request() method. All the work is done here.
        #
        def request (method, args, &block)

            # prepare request

            opts = EndPoint.extract_opts args

            compute_target opts

            req = create_request method, opts

            add_payload(req, opts, &block) if method == :post or method == :put

            add_authentication(req, opts)

            add_conditional_headers(req, opts) if method == :get

            mention_cookies(req, opts)
                # if the :cookies option is disabled (the default)
                # will have no effect

            vlog_request opts, req

            return req if o(opts, :dry_run) == true

            # trigger request

            http = prepare_http opts

            vlog_http opts, http

            res = nil

            http.start do
                res = http.request req
            end

            # handle response

            class << res
                attr_accessor :request
            end
            res.request = req

            vlog_response opts, res

            register_cookies res, opts
                # if the :cookies option is disabled (the default)
                # will have no effect

            return res if o(opts, :raw_response)

            check_authentication_info res, opts
                # used in case of :digest_authentication
                # will have no effect else

            res = handle_response method, res, opts

            return parse_options(res) if method == :options

            return res.body if o(opts, :body)

            res
        end

        private

            #
            # Manages various args formats :
            #
            #     uri
            #     [ uri ]
            #     [ uri, opts ]
            #     opts
            #
            def self.extract_opts (args)

                opts = {}

                args = [ args ] unless args.is_a?(Array)

                opts = args.last \
                    if args.last.is_a?(Hash)

                opts[:uri] = args.first \
                    if args.first.is_a?(String) or args.first.is_a?(URI)

                opts
            end

            #
            # Returns the value from the [request] opts or from the
            # [endpoint] @opts.
            #
            def o (opts, key)

                keys = Array key
                keys.each { |k| (v = opts[k]; return v if v != nil) }
                keys.each { |k| (v = @opts[k]; return v if v != nil) }
                nil
            end

            #
            # Returns scheme, host, port, path, query
            #
            def compute_target (opts)

                u = opts[:uri] || opts[:u]

                r = if opts[:host]

                    [ opts[:scheme] || 'http',
                      opts[:host],
                      opts[:port]  || 80,
                      opts[:path] || '/',
                      opts[:query] || opts[:params] ]

                elsif u

                    u = URI.parse u.to_s unless u.is_a?(URI)
                    [ u.scheme,
                      u.host,
                      u.port,
                      u.path,
                      query_to_h(u.query) ]
                else

                    []
                end

                opts[:scheme] = r[0] || @opts[:scheme]
                opts[:host] = r[1] || @opts[:host]
                opts[:port] = r[2] || @opts[:port]
                opts[:path] = r[3] || @opts[:path]

                opts[:query] =
                    r[4] ||
                    opts[:params] || opts[:query] ||
                    @opts[:query] || @opts[:params] ||
                    {}

                opts.delete :path if opts[:path] == ""

                opts[:c_uri] = [
                    opts[:scheme],
                    opts[:host],
                    opts[:port],
                    opts[:path],
                    opts[:query] ].inspect
                        #
                        # can be used for conditional gets

                r
            end

            #
            # Creates the Net::HTTP request instance.
            #
            # If :fake_put is set, will use Net::HTTP::Post
            # and make sure the query string contains '_method=put' (or
            # '_method=delete').
            #
            # This call will also advertise this rufus-verbs as
            # 'accepting the gzip encoding' (in case of GET).
            #
            def create_request (method, opts)

                if (o(opts, :fake_put) and
                    (method == :put or method == :delete))

                    opts[:query][:_method] = method.to_s
                    method = :post
                end

                path = compute_path opts

                r = eval("Net::HTTP::#{method.to_s.capitalize}").new path

                r['User-Agent'] = o(opts, :user_agent)
                    # potentially overriden by opts[:headers]

                h = opts[:headers] || opts[:h]
                h.each { |k, v| r[k] = v } if h

                r['Accept-Encoding'] = 'gzip' \
                    if method == :get and not o(opts, :nozip)

                r
            end

            #
            # If @user and @pass are set, will activate basic authentication.
            # Else if the @auth option is set, will assume it contains a Proc
            # and will call it (with the request as a parameter).
            #
            # This comment is too much... Just read the code...
            #
            def add_authentication (req, opts)

                b = o(opts, :http_basic_authentication)
                d = o(opts, :digest_authentication)
                o = o(opts, :auth)

                if b and b != false

                    req.basic_auth b[0], b[1]

                elsif d and d != false

                    digest_auth req, opts

                elsif o and o != false

                    o.call req
                end
            end

            #
            # In that base class, it's empty.
            # It's implemented in ConditionalEndPoint.
            #
            # Only called for a GET.
            #
            def add_conditional_headers (req, opts)

                # nada
            end

            #
            # Prepares a Net::HTTP instance, with potentially some
            # https settings.
            #
            def prepare_http (opts)

                compute_proxy opts

                http = Net::HTTP.new(
                    opts[:host], opts[:port],
                    opts[:proxy_host], opts[:proxy_port],
                    opts[:proxy_user], opts[:proxy_pass])

                set_timeout http, opts

                return http unless opts[:scheme] == 'https'

                require 'net/https'

                http.use_ssl = true
                http.enable_post_connection_check = true

                http.verify_mode = if o(opts, :ssl_verify_peer)
                    OpenSSL::SSL::VERIFY_PEER
                else
                    OpenSSL::SSL::VERIFY_NONE
                end

                store = OpenSSL::X509::Store.new
                store.set_default_paths
                http.cert_store = store

                http
            end

            #
            # Sets both the open_timeout and the read_timeout for the http
            # instance
            #
            def set_timeout (http, opts)

                to = o(opts, :timeout) || o(opts, :to)
                to = to.to_i

                return if to == 0

                http.open_timeout = to
                http.read_timeout = to
            end

            #
            # Makes sure the request opts hold the proxy information.
            #
            # If the option :proxy is set to false, no proxy will be used.
            #
            def compute_proxy (opts)

                p = o(opts, :proxy)

                return unless p

                u = URI.parse p.to_s

                raise "not an HTTP[S] proxy '#{u.host}'" \
                    unless u.scheme.match(/^http/)

                opts[:proxy_host] = u.host
                opts[:proxy_port] = u.port
                opts[:proxy_user] = u.user
                opts[:proxy_pass] = u.password
            end

            #
            # Determines the full path of the request (path_info and
            # query_string).
            #
            # For example :
            #
            #     /items/4?style=whatever&maxcount=12
            #
            def compute_path (opts)

                b = o(opts, :base)
                r = o(opts, [ :res, :resource ])
                i = o(opts, :id)

                path = o(opts, :path)

                if b or r or i
                    path = ""
                    path = "/#{b}" if b
                    path += "/#{r}" if r
                    path += "/#{i}" if i
                end

                path = path[1..-1] if path[0..1] == '//'

                query = opts[:query] || opts[:params]

                return path if not query or query.size < 1

                path + '?' + h_to_query(query, opts)
            end

            #
            #     "a=A&b=B" -> { "a" => "A", "b" => "B" }
            #
            def query_to_h (q)

                return nil unless q

                q.split("&").inject({}) do |r, e|
                    s = e.split("=")
                    r[s[0]] = s[1]
                    r
                end
            end

            #
            #     { "a" => "A", "b" => "B" } -> "a=A&b=B"
            #
            def h_to_query (h, opts)

                h.entries.collect { |k, v|
                    unless o(opts, :no_escape)
                        k = URI.escape k.to_s
                        v = URI.escape v.to_s
                    end
                    "#{k}=#{v}"
                }.join("&")
            end

            #
            # Fills the request body (with the content of :d or :fd).
            #
            def add_payload (req, opts, &block)

                d = opts[:d] || opts[:data]
                fd = opts[:fd] || opts[:form_data]

                if d
                    req.body = d
                elsif fd
                    sep = opts[:fd_sep] #|| nil
                    req.set_form_data fd, sep
                elsif block
                    req.body = block.call req
                else
                    req.body = ""
                end
            end

            #
            # Handles the server response.
            # Eventually follows redirections.
            #
            # Once the final response has been hit, will make sure
            # it's decompressed.
            #
            def handle_response (method, res, opts)

                nored = o(opts, [ :no_redirections, :noredir ])

                #if res.is_a?(Net::HTTPRedirection)
                if [ 301, 303, 307 ].include?(res.code.to_i) and (nored != true)

                    maxr = o(opts, :max_redirections)

                    if maxr
                        maxr = maxr - 1
                        raise "too many redirections" if maxr == -1
                        opts[:max_redirections] = maxr
                    end

                    location = res['Location']

                    prev_host = [ opts[:scheme], opts[:host] ]

                    if location.match /^http/
                        u = URI::parse location
                        opts[:scheme] = u.scheme
                        opts[:host] = u.host
                        opts[:port] = u.port
                        opts[:path] = u.path
                        opts[:query] = u.query
                    else
                        opts[:path], opts[:query] = location.split "?"
                    end

                    if (authentication_is_on?(opts) and
                        [ opts[:scheme], opts[:host] ] != prev_host)

                        raise(
                            "getting redirected to #{location} while " +
                            "authentication is on. Stopping.")
                    end

                    opts[:query] = query_to_h opts[:query]

                    return request(method, opts)
                        #
                        # following the redirection
                end

                decompress res

                res
            end

            #
            # Returns an array of symbols, like for example
            #
            #     [ :get, :post ]
            #
            # obtained by parsing the 'Allow' response header.
            #
            # This method is used to provide the result of an OPTIONS
            # HTTP method.
            #
            def parse_options (res)

                s = res['Allow']

                return [] unless s

                s.split(",").collect do |m|
                    m.strip.downcase.to_sym
                end
            end

            #
            # Returns true if the current request has authentication
            # going on.
            #
            def authentication_is_on? (opts)

                (o(opts, [ :http_basic_authentication, :hba, :auth ]) != nil)
            end

            #
            # Inflates the response body if necessary.
            #
            def decompress (res)

                if res['content-encoding'] == 'gzip'

                    class << res

                        attr_accessor :deflated_body

                        alias :old_body :body

                        def body
                            @deflated_body || old_body
                        end
                    end
                        #
                        # reopened the response to add
                        # a 'deflated_body' attr and let the the body
                        # method point to it

                    # now deflate...

                    io = StringIO.new res.body
                    gz = Zlib::GzipReader.new io
                    res.deflated_body = gz.read
                    gz.close
                end
            end
    end
end
end


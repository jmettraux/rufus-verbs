
#
# Testing rufus-verbs
#
# jmettraux@gmail.com
#
# Sat Jan 19 18:22:48 JST 2008
#

require 'test/unit'
#require 'testbase'

require 'rufus/verbs'
require 'rufus/verbs/cookies'


class Cookie0Test < Test::Unit::TestCase
    #include TestBaseMixin

    include Rufus::Verbs::CookieMixin
    include Rufus::Verbs::HostMixin

    #
    # testing split_host(s)
    #
    def test_0

        assert_equal [ 'localhost', nil ], split_host('localhost')
        assert_equal [ 'benz', '.car.co.nz' ], split_host('benz.car.co.nz')
        assert_equal [ '127.0.0.1', nil ], split_host('127.0.0.1')
        assert_equal [ '::1', nil ], split_host('::1')
    end

    #
    # testing the CookieJar
    #
    def test_1

        cookie0 = TestCookie.new
        cookie1 = TestCookie.new

        jar = Rufus::Verbs::CookieJar.new 77
        assert_equal 0, jar.size

        jar.add_cookie(".rubyforge.org", "/", cookie0)
        assert_equal 1, jar.size
        assert_equal [ cookie0 ], jar.fetch_cookies("rufus.rubyforge.org", "/main")

        jar.add_cookie("rufus.rubyforge.org", "/sub", cookie1)
        assert_equal 2, jar.size
        assert_equal [ cookie1, cookie0 ], jar.fetch_cookies("rufus.rubyforge.org", "/sub/0")
        assert_equal [ cookie0 ], jar.fetch_cookies("rufus.rubyforge.org", "/main")
        assert_equal [ cookie0 ], jar.fetch_cookies("rufus.rubyforge.org", "/")

        jar.remove_cookie("rufus.rubyforge.org", "/sub", cookie1)
        assert_equal 1, jar.size
    end

    #
    # testing cookie_acceptable?(opts, cookie)
    #
    def test_2

        jar = Rufus::Verbs::CookieJar.new 77

        opts = { :host => 'rufus.rubyforge.org', :path => '/' }
        c = TestCookie.new '.rubyforge.org', '/'
        r = TestResponse.new opts
        assert cookie_acceptable?(opts, r, c)

        # * The value for the Domain attribute contains no embedded dots
        #   or does not start with a dot.

        opts = { :host => 'rufus.rubyforge.org', :path => '/' }
        c = TestCookie.new 'rufus.rubyforge.org', '/'
        r = TestResponse.new opts
        assert ! cookie_acceptable?(opts, r, c)

        opts = { :host => 'rufus.rubyforge.org', :path => '/' }
        c = TestCookie.new 'org', '/'
        r = TestResponse.new opts
        assert ! cookie_acceptable?(opts, r, c)

        # * The value for the Path attribute is not a prefix of the 
        #   request-URI.

        opts = { :host => 'rufus.rubyforge.org', :path => '/this' }
        c = TestCookie.new '.rubyforge.org', '/that'
        r = TestResponse.new opts
        assert ! cookie_acceptable?(opts, r, c)

        # * The value for the request-host does not domain-match the 
        #   Domain attribute.

        opts = { :host => 'rufus.rubyforg.org', :path => '/' }
        c = TestCookie.new '.rubyforge.org', '/'
        r = TestResponse.new opts
        assert ! cookie_acceptable?(opts, r, c)

        # * The request-host is a FQDN (not IP address) and has the form
        #   HD, where D is the value of the Domain attribute, and H is a
        #   string that contains one or more dots.
        
        # implicit...
    end

    #def test_webrick_cookie
    #    require 'webrick/cookie'
    #    cookie = "PREF=ID=18da97219de4985:TM=12007507:LM=12007507:S=Guc1JcA15ySZYl2n; expires=Mon, 18-Jan-2010 09:30:37 GMT; path=/; domain=.google.com"
    #    p WEBrick::Cookie.parse_set_cookie(cookie)
    #    p Rufus::Verbs::Cookie.parse_set_cookie(cookie)
    #end

    protected

        class TestCookie

            attr_reader :domain, :path, :name

            def initialize (domain=nil, path=nil, name='whatever')

                @domain = domain
                @path = path
                @name = name
            end
        end

        class TestResponse

            def initialize (opts)

                @path = opts[:path]
            end

            def request

                r = Object.new
                class << r
                    attr_accessor :path
                end
                r.path = @path
                r
            end
        end
end

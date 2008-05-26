
#
# an in-memory resource set for testing rufus-verbs
#
# jmettraux@gmail.com
#
# Fri Jan 11 12:36:45 JST 2008
#

require 'date'
require 'webrick'


$dcount = 0 # tracking the number of hits when doing digest auth


#
# the hash for the /items resource (collection)
#
class LastModifiedHash

    def initialize

        @hash = {}
        touch
    end

    def touch (key=nil)

        now = Time.now.httpdate
        @hash[key] = now if key
        @hash['__self'] = now
    end

    def delete (key)

        @hash.delete key
        @hash['__self'] = Time.now.httpdate
    end

    def last_modified (key)

        key = key || '__self'
        @hash[key]
    end

    def clear

        @hash.clear
        @hash['__self'] = Time.now.httpdate
    end
end


#
# This servlet provides a RESTful in-memory resource "/items".
#
class ItemServlet < WEBrick::HTTPServlet::AbstractServlet

    @@items = {}
    @@last_item_id = -1

    @@lastmod = LastModifiedHash.new

    @@authenticator = WEBrick::HTTPAuth::DigestAuth.new(
        :UserDB => WEBrick::HTTPAuth::Htdigest.new('test/test.htdigest'),
        :Realm => 'test_realm')

    def initialize (server, *options)

        super
        @auth = server.auth
    end

    #
    # Overriding the service() method to perform a potential auth check
    #
    def service (req, res)

        if @auth == :basic

            WEBrick::HTTPAuth.basic_auth(req, res, "items") do |u, p|
                (u != nil and u == p)
            end

        elsif @auth == :digest

            $dcount += 1
            @@authenticator.authenticate(req, res)
        end

        super
    end

    def do_GET (req, res)

        i = item_id req

        return reply(res, 404, "no item '#{i}'") \
            if i and not items[i]

        representation, et, lm = fetch_representation i

        since = req['If-Modified-Since']
        since = DateTime.parse(since) if since
        match = req['If-None-Match']

        if ((not since and not match) or
            (since and (since > DateTime.parse(lm))) or
            (match and (match != et)))

            res['Etag'] = et
            res['Last-Modified'] = lm
            res.body = representation.inspect + "\n"

        else

            reply(res, 304, "Not Modified")
        end
    end

    def do_POST (req, res)

        query = WEBrick::HTTPUtils::parse_query(req.query_string)
        m = query['_method']
        m = m.downcase if m
        return do_PUT(req, res) if m == 'put'
        return do_DELETE(req, res) if m == 'delete'

        i = item_id req

        i = (@@last_item_id += 1) unless i

        items[i] = req.body
        lastmod.touch i

        res['Location'] = "#{@host}/items/#{i}"
        reply res, 201, "item created"
    end

    def do_PUT (req, res)

        i = item_id req

        return reply(res, 404, "no item '#{i}'") unless items[i]

        items[i] = req.body
        lastmod.touch i

        reply res, 200, "item updated"
    end

    def do_DELETE (req, res)

        i = item_id req

        return reply(res, 404, "no item '#{i}'") unless items[i]

        items.delete i
        lastmod.delete i

        reply res, 200, "item deleted"
    end

    #
    # clears the items
    #
    def self.flush

        @@items.clear
        @@lastmod.clear
    end

    protected

        def items
            @@items
        end

        def lastmod
            @@lastmod
        end

        def is_modified (req, key)

            since = req['If-Modified-Since']
            match = req['If-None-Match']

            return true unless since or match

            #puts
            #p [ since, match ]
            #puts

            (since or match)
        end

        #
        # Returns representation, etag, last_modified
        #
        def fetch_representation (key=nil)

            representation = if key
                items[key]
            else
                items
            end

            [ representation,
              representation.inspect.hash.to_s,
              lastmod.last_modified(key) ]
        end

        def reply (res, code, message)

            res.status = code
            res.body = message + "\n"
            res['Content-type'] = "text/plain"
        end

        def item_id (req)

            p = req.path_info[1..-1]
            return nil if not p or p == ''
            p.to_i
        end
end

#
# just redirecting to the ItemServlet...
#
class ThingServlet < WEBrick::HTTPServlet::AbstractServlet

    def do_GET (req, res)

        res.set_redirect(
            WEBrick::HTTPStatus[303],
            "http://localhost:7777/items")
    end
end

#
# testing Rufus::Verbs cookies...
#
class CookieServlet < WEBrick::HTTPServlet::AbstractServlet

    @@sessions = {}

    def do_GET (req, res)

        res.body = get_session(req, res).inspect
    end

    def do_POST (req, res)

        get_session(req, res) << req.body.strip
        res.body = "ok."
    end

    protected

        def get_session (req, res)

            c = req.cookies.find { |c| c.name == 'tcookie' }

            if c
                @@sessions[c.value]
            else
                s = []
                key = (Time.now.to_f * 100000).to_i.to_s
                @@sessions[key] = s
                res.cookies << WEBrick::Cookie.new('tcookie', key)
                s
            end
        end
end

#
# a servlet that doesn't reply (for timeout testing)
#
class LostServlet < WEBrick::HTTPServlet::AbstractServlet

    def do_GET (req, res)

        sleep 200
    end
end

#
# Serving items, a dummy resource...
# Also serving things, which just redirect to items...
#
class ItemServer

    def initialize (args={})

        port = args[:port] || 7777

        #al = [
        #    [ "", WEBrick::AccessLog::COMMON_LOG_FORMAT ],
        #    [ "", WEBrick::AccessLog::REFERER_LOG_FORMAT ]]

        @server = WEBrick::HTTPServer.new :Port => port, :AccessLog => nil

        class << @server
            attr_accessor :auth
        end

        @server.auth = args[:auth]

        @server.mount "/items", ItemServlet
        @server.mount "/things", ThingServlet
        @server.mount "/cookie", CookieServlet
        @server.mount "/lost", LostServlet

        [ 'INT', 'TERM' ].each do |signal|
            trap(signal) { shutdown }
        end
    end

    def start

        Thread.new { @server.start }
            # else the server and the test lock each other
    end

    def shutdown

        ItemServlet.flush
        @server.shutdown
    end
end


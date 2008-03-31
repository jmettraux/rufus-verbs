
# 
# The original version of this benchmark can be found at :
# 
#     http://m.onkey.org/2008/2/2/tidbits-from-my-crap
#
# By running it, you'll simply learn that rufus-verbs perform like
# net/http which it wraps.
# Seems a bit better than open-uri though.
#
# Mon Feb 18 09:17:02 JST 2008
# 

#['rubygems', 'benchmark', 'eventmachine', 'net/http', 'open-uri', 'rfuzz/session'].each {|lib| require lib }
['rubygems', 'benchmark', 'net/http', 'open-uri', 'rufus/verbs' ].each {|lib| require lib }

server      = 'tiramisu'
port        = 80
request_uri = "http://#{server}:#{port}/"

def run(name, x)
  x.report(name) do
    100.times do
      yield
    end
  end
end

uri = URI.parse(request_uri)
puts Net::HTTP.get(uri)

#rfuzz = RFuzz::HttpClient.new(server, port)
#puts rfuzz.get('/').http_body

puts open(request_uri).read

#puts Rufus::Verbs.get(uri)
puts Rufus::Verbs.get(request_uri)

#EM.epoll
#http = nil
#EM.run do
#  http = EM::Protocols::HttpClient2.connect(server, port).get("/")
#  http.callback { EM.stop  }
#end
#puts http.content
#EM.run { EM::Protocols::HttpClient2.connect(server, port).get("/").callback { EM.stop  } }

Benchmark.bm do |x|
  
  run("Ruby Net::HTTP ", x) do
    Net::HTTP.get(uri)
  end
  
  run("Open URI       ", x) do
    open(request_uri).read
  end

  run("Rufus-verbs    ", x) do
    #Rufus::Verbs.get(uri)
    Rufus::Verbs.get(request_uri)
  end
  
  #run("RFuzz          ", x) do
  #  rfuzz.get('/').http_body
  #end
  
  #run("Event Machine  ", x) do
  #  EM.run { EM::Protocols::HttpClient2.connect(server, port).get("/").callback {  EM.stop } }
  #end
  
end

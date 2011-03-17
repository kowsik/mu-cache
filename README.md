## Mu::Cache
A simple in-memory, time and size-limited cache that you can use in Sinatra 
apps to minimize calls to CouchDB where appropriate. Since it acts like a Hash, 
you can also do timed caches of HAML fragments (like refreshing a scoreboard). This is
very different from [Rack::Cache](http://tomayko.com/writings/rack-cache-announce) 
or other caching routines that persist the cache for eternity. This is also not 
a replacement for `redis` or `memcached`. Because it's built into the app, there's 
no network latency to go and fetch the RAM-based cache. The expiration of
entries either based on the `max_size` or the `max_time` is amortized over
multiple requests. There's no `Thread` that sweeps the cache periodically.

In your Application add this:

    def self.cache
        @@cache ||= Mu::Cache.new :max_size => 1024, :max_time => 30.0
    end
    
And maybe in the `before` route:

    before do
        session_id = session[:id]
        if session_id
            @account = cache.fetch session_id do
                DB.get session_id rescue nil
            end
        end
    end

The cache size as well as the time for which the entries are held is configured
when you first create it. You can also have multiple caches of different sizes
and expiration times in the same app. Any time the cache is accessed, the
`purger` runs to remove entries that have expired. If an entry is `touched`
it's moved to the front of the cache so you can have long-lasting entries
that are constantly accessed. If you want to explicitly expire the cache and
refetch after the expiration timeout, simple pass `false` to the `fetch` method.

For example:

    get '/scoreboard' do
        Application.cache.fetch 'scoreboard', false do
            # At least 30 seconds has to elapse before this is called
            haml :scoreboard
        end
    end

We use this in [blitz.io](http://blitz.io) for various aspects including
minimizing CouchDB calls, scoreboard rendering, etc and found it to be handy.
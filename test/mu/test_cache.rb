require 'helper'

module Mu
class Cache
class Test < Test::Unit::TestCase
    attr_reader :cache
    
    def setup
        @cache = Cache.new
    end
    
    def test_entry
        entry = Entry.new
        assert_nil entry.key
        assert_nil entry.val
        assert_nil entry.next
        assert_nil entry.prev
        
        entry = Entry.new :k1
        assert_equal :k1, entry.key
        assert_nil entry.val
        assert_nil entry.next
        assert_nil entry.prev
        
        entry = Entry.new :k1, :v1
        assert_equal :k1, entry.key
        assert_equal :v1, entry.val
        assert_nil entry.next
        assert_nil entry.prev
    end
    
    def test_cache_empty
        assert_equal 0, cache.size
    end
    
    def test_cache_fetch_yield
        assert_throws :gotit do
            cache.fetch 'key' do
                throw :gotit
            end
        end
        
        cache.fetch(:k1) { :v1 }
        assert_equal 1, cache.size
        head = cache.__send__(:list).head
        assert_equal :k1, head.key
        assert_equal :v1, head.val
        
        assert_nothing_thrown do
            val = cache.fetch(:k1) { throw :gotit }
            assert_equal :v1, val
        end
        
        cache.fetch(:k2) { :v2 }
        assert_equal 2, cache.size
        head = cache.__send__(:list).head
        assert_equal [ :k1, :v1 ], [ head.key, head.val ]
        assert_equal [ :k2, :v2 ], [ head.next.key, head.next.val ]
        
        assert_nothing_thrown do
            val = cache.fetch :k2
            assert_equal :v2, val
        end
    end
    
    def test_cache_fetch_exception
        val = cache.fetch(:key) { raise "bummer" }
        assert_nil val
    end
    
    def test_fetch
        (1..10).each do |i|
            cache.store "k#{i}", "v#{i}"
        end
    
        assert_equal 10, cache.size
        
        v = cache.fetch 'k1'
        assert_equal 'v1', v
        entry = cache.__send__(:list).tail
        assert_equal [ 'k1', 'v1' ], [ entry.key, entry.val ]
        
        v = cache.fetch 'k2'
        assert_equal 'v2', v
        entry = cache.__send__(:list).tail
        assert_equal [ 'k2', 'v2' ], [ entry.key, entry.val ]        
        assert_equal [ 'k1', 'v1' ], [ entry.prev.key, entry.prev.val ]
    end
    
    def test_store
        cache.fetch(:k1) { :v1 }
        cache.store :k1, :v2
        head = cache.__send__(:list).head
        assert_equal [ :k1, :v2 ], [ head.key, head.val ]
    end
    
    def test_fetch_complex_key
        cache.fetch([:part1, :part2]) { :v1 }
        v = cache.fetch [:part1, :part2]
        assert_equal :v1, v
    end
    
    def test_delete
        (1..10).each do |i|
            cache.store "k#{i}", "v#{i}"
        end
        
        assert_equal 10, cache.size
        v = cache.delete 'k1'
        assert_equal 'v1', v
        assert_equal 9, cache.size
        
        v = cache.delete 'non-existent-key'
        assert_nil v
        
        v = cache.delete 'k10'
        assert_equal 'v10', v
        assert_equal 8, cache.size
    end
    
    def test_purge_size
        (1..10).each do |i|
            cache.store "k#{i}", "v#{i}"
        end
        
        assert_equal 10, cache.size        
        cache.__send__ :purge, :max_size => 2
        assert_equal 2, cache.size
        
        head = cache.__send__(:list).head
        assert_equal [ 'k9', 'v9' ], [ head.key, head.val ]
        assert_equal [ 'k10', 'v10' ], [ head.next.key, head.next.val ]
    end
    
    def test_purge_time
        (1..10).each do |i|
            cache.store "k#{i}", "v#{i}"
        end
        
        assert_equal 10, cache.size
        sleep 0.5
        cache.__send__ :purge, :max_time => 0.1
        assert_equal 0, cache.size
    end
end
end # Cache
end # Mu

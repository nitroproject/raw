# Global scoped variables. This is backed by a Cache store.
#--
# TODO: implement as a refactoring of session?
#++

class Global

  # The type of the global cache. The generalized caching
  # system in Opod is used. The following options are available:
  #
  # * :memory [default]
  # * :drb
  # * :og
  # * :file
  # * :memcached

  setting :cache_type, :default => :memory, :doc => 'The type of global cache'

  # The address of the store.

  setting :cache_address, :default => '127.0.0.1', :doc => 'The address of the global cache'

  # The port of the store.

  setting :cache_port, :default => 9079, :doc => 'The port of the global cache'

  class << self
    # The global cache (store).

    attr_accessor :cache

    # Init the correct Global cache.

    def setup(type = Global.cache_type)
      return if Global.cache

      case type
        when :memory
          require 'opod/memory'
          Global.cache = Opod::MemoryCache.new

        when :drb
          require 'opod/drb'
          Global.cache = Opod::DrbCache.new(Global.cache_address, Global.cache_port)
      end
    end

    # Initialize a global value once.

    def init(key, value)
      unless Global[key]
        Global[key] = value
      end
    end

    def set(key, value)
      Global.cache[key] = value
    end
    alias_method :[]=, :set

    def get(key)
      return Global.cache[key]
    end
    alias_method :[], :get

    # If block is given it acts as an update methods,
    # that transparently handles distributed stores.
    #
    # Global.update(:USERS) do |users|
    #   users << 'gmosx'
    # end

    def update(key)
      if block_given?
        # update, also handles distributed stores.
        val = Global.cache[key]
        yield val
        Global.cache[key] = val
      end
    end

    def delete(key)
      Global.cache.delete(key)
    end

  end

end

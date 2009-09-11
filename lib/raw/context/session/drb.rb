require "opod/drb"
require "raw/context/session/memory"

module Raw

class Session < Hash
  # The address of the cache store.

  setting :cache_address, :default => "127.0.0.1", :doc => "The address of the cache store"

  # The port of the cache store.

  setting :cache_port, :default => 9069, :doc => "The port of the cache store"
end

class DrbSessionStore < MemorySessionStore

  def initialize
    info "Using DRb sessions at #{Session.cache_address}:#{Session.cache_port}."
    @cache = Opod::DrbCache.new(Session.cache_address, Session.cache_port)
  end

end

end

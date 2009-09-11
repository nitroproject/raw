require "opod/memcached"

require "raw/context/session"

module Raw

# A Session manager that persists sessions on disk.

debug "Using MemCached sessions." if defined?(Logger) && $DBG

Session.cache = Opod::MemCached.new("session_#{Session.cookie_name}", Session.keepalive)

end

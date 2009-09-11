require "opod/og"

require "raw/context/session"

module Raw

# A Session manager that persists sessions on an Og store.

debug "Using Og sessions." if defined?(Logger) && $DBG

Session.cache = OgCache.new("session_#{Session.cookie_name}", Session.keepalive)

end

require "opod/file"

require "raw/context/session"

module Raw

# A Session manager that persists sessions on disk.

info "Using File sessions." if defined?(Logger) && $DBG

Session.cache = Opod::FileCache.new("session_#{Session.cookie_name}", Session.keepalive)

end


require "opod/pstore"

require "raw/context/session"

module Raw

# A Session manager that is using PStore to store state

info "Using PStore sessions." if defined?(Logger)

Session.cache = Opod::PStoreCache.new(Session.keepalive)

end

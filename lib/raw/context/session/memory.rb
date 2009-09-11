require "digest/sha2"

require "opod/memory"

module Raw

class MemorySessionStore < SessionStore

  # The cache used to store sessions.

  attr_accessor :cache

  def initialize
    @cache = Opod::MemoryCache.new
  end

  # Get the session for this context.

  def get(context = Context.current)
    if digest = context.cookies[Session.cookie_name]
      session = @cache[digest]
    end

  ensure
    unless session
      digest = generate_digest()
      session = Session.new
      session.instance_variable_set("@digest", digest)
      @cache[digest] = session
    end

    return session
  end

  # Restore the session to the store.

  def put(session, context = Context.current)
    digest = session.instance_variable_get("@digest")
    @cache[digest] = session
    cookie = Cookie.new(Session.cookie_name, digest)
    context.add_cookie(cookie)
  end

  # Delete the session from the store.

  def delete(session, context = Context.current)
    digest = session.instance_variable_get("@digest")
    @cache.delete(digest)
    super
  end

private

  # Calculates a unique session id. The session id must be
  # unique, a monotonically increasing function like time is
  # appropriate. Random may produce equal ids?

  def generate_digest
    Digest::SHA512.hexdigest("#{Time.now.usec}#{rand(100)}#{Session.secret}")
  end

end

end


__END__

from the old implementation:

# Perform Session garbage collection. You may call this
# method from a cron job.

def garbage_collect
  expired = []
  for s in Session.cache.all
    expired << s.session_id if s.expired?
  end
  for sid in expired
    Session.cache.delete(sid)
  end
end
alias_method :gc!, :garbage_collect

require "facets/expirable"
require "facets/settings"
require "facets/times"

module Raw

# A web application session. 
#
# State is a neccessary evil but session variables
# should be avoided as much as possible. Session state 
# is typically distributed to many servers so avoid 
# storing complete objects in session variables, only 
# store oids and small integer/strings.
# 
# The session should be persistable to survive server 
# shutdowns.
#
# The session can be considered as a Hash where key-value
# pairs are stored. Typically symbols are used as keys. By
# convention uppercase symbols are used for internal system
# session parameters (ie :FLASH, :USER, etc). User applications
# typically use lowercase symbols (ie :cart, :history, etc).

class Session < Hash
  is Expirable

  # The name of the cookie that stores the session.
  
  setting :cookie_name, :default => "ns", :doc => "The name of the cookie that stores the session"

  # The expires value for the session cookie, nil means expire at the end of the session.
  
  setting :cookie_expires, :default => nil, :doc => "The expires value for the session cookie"

  # The secret used to generate digests.
  
  setting :secret, :default => "public", :doc => "The secret used to generate the digest"
    
  # The session keepalive time. The session is eligable for
  # garbage collection after this time passes.
  
  setting :keepalive, :default => 30.minutes, :doc => "The session keepalive time"

  # Create the session for the given context.
  # If the hook method 'created' is defined it is called
  # at the end. Typically used to initialize the session
  # hash.

  def initialize(hash = nil)
    super()
    update(hash) if hash
    expires_after(Session.keepalive)
    created()
  end

  # Override this callback if you need to initialize some 
  # session data.
  
  def created
  end

  def [](key)
    super(key.to_s)
  end
  
  def []=(key, val)
    super(key.to_s, val)
  end
  
  def delete(key)
    super(key.to_s)
  end
end

# A store for sessions.

class SessionStore
  
  # Get the session for this context.
  
  def get(context = Context.current)
  end
  
  # Restore the session to the store.
  
  def put(session, context = Context.current)
  end

  # Delete the session from the store.
  
  def delete(session, context = Context.current)
    cookie = Cookie.new(Session.cookie_name, "")
    cookie.expires = 1.year.ago
    context.add_cookie(cookie)
    context.no_sync!
  end
    
end

end

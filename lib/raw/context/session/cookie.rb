require "base64"
require "digest/sha2"

require "blow/json"

module Raw

# A cookie based session store. Session data is stored in a 
# cookie. As web applications should try minimize the session 
# data they use, typical sessions fit within the 4Kb cookie
# size limit.
#
# This store is the default Session Store. If you have more than 
# 4Kb of session data or don't want your data to be visible to 
# the user, pick another session store.

class CookieSessionStore < SessionStore

  class AlteredCookie < StandardError; end

  def get(context = Context.current)
    if data = context.cookies[Session.cookie_name]
      context.instance_variable_set("@cookie_session_store_original", CGI.escape(data))
      session = decode(data)
    end

  rescue AlteredCookie
    delete(nil) # Delete the invalid cookie from the client.
    info "Found altered cookie"

  ensure
    unless session
      context.instance_variable_set("@cookie_session_store_original", nil)
      session = Session.new
    end

    return session
  end

  def put(session, context = Context.current)
    data = encode(session)

    unless data == context.instance_variable_get("@cookie_session_store_original")    
      # Session data changed, update the cookie.

      cookie = Cookie.new(Session.cookie_name, data)
      cookie.expires = 1.year.from_now # Session.cookie_expires
      context.add_cookie(cookie)

      # Also send the session data in JSON format to make
      # accessible to the client.

      cookie = Cookie.new("#{Session.cookie_name}c", encode_client(session))
      cookie.expires = 1.year.from_now # Session.cookie_expires
      context.add_cookie(cookie)
    end
  end

  # Delete the session from the store.

  def delete(session, context = Context.current)
    super
    cookie = Cookie.new("#{Session.cookie_name}c", "")
    cookie.expires = 1.year.ago
    context.add_cookie(cookie)
    context.no_sync!
  end

private

  # Base64 encoding is used to make the marshaled data HTTP 
  # header friendly. A diggest is added for extra security.

  def encode(session)
    data = Base64.encode64(Marshal.dump(session)).chop
    data = CGI.escape("#{data}--#{generate_digest(data)}")
    raise "Session data size exceeds the cookie size limit" if data.size > 4096
    return data
  end

  # Encode the session data in a client accessible format. No
  # signing is needed.

  def encode_client(session)
    return CGI.escape(Base64.encode64(JSON.unparse(session)))
  end

  # Decode the cookie data. Returns nil if the cookie is 
  # altered.

  def decode(data)
# gmosx: 
# NO NEED to unescape, cookie data is already unescaped! this 
# fixes a NASTY bug (Base64 uses '+'):
#
#   >> x = CGI.escape("hey+there")
#   => "hey%2Bthere"
#   >> CGI.unescape(x)
#   => "hey+there"
#   >> CGI.unescape(CGI.unescape(x))
#   => "hey there"
#
#    decrypted_data, digest = CGI.unescape(data).split("--")
     decrypted_data, digest = data.split("--")
    raise AlteredCookie.new unless digest == crypt(decrypted_data)
    return Marshal.load(Base64.decode64(decrypted_data))
  end

  # Generate the security digest.

  def generate_digest(data)
    Digest::SHA512.hexdigest("#{data}#{Session.secret}")
  end
  alias_method :crypt, :generate_digest

end

end


if __FILE__ == $0

  #--
  # gmosx: PLEASE move this to a separate test file!
  #++

  BEGIN {
    require "facets"
    require "facets/random"
    require "cgi"

    require "raw/context/session"
    require "raw/controller/cookie"
  }

  require "test/unit"

  class TestCookie < Test::Unit::TestCase

    class MockContext
      def initialize
        @cookies = {}
        @data = {}
      end
      def cookies
        @data
      end
      def add_cookie(cookie)
        @cookies[cookie.name] = cookie
        @data[cookie.name] = cookie.value
      end
    end

    def setup
      @cookie_store = Raw::CookieSessionStore.new
    end

    def test_simple
      context = MockContext.new
      input = "RABBIT DATA"
      @cookie_store.put(input, context)
      output = @cookie_store.get(context)
      assert_equal(input, output)
    end

    context = MockContext.new
    maxsize = 1000

    1000.times do |i|
      input = String.random((rand * maxsize).to_i, /[\w\W]/)

      define_method("test_#{i}") do
        @cookie_store.put(input, context)
        output =  @cookie_store.get(context)
        assert_equal(input, output)
      end
    end

  end

end

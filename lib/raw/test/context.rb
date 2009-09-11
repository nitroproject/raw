require 'test/unit'
require 'test/unit/assertions'
require 'rexml/document'

require 'raw/context'

module Raw

# Override the default Request implementation
# to include methods useful for testing.

module Request
end

# Override the default Response implementation
# to include methods useful for testing.

module Response

  def status_ok?
    @status == 200
  end

  def redirect?
    (300..399).include?(@status)
  end

  def redirect_uri
    @response_headers['location']
  end

  def response_cookie(name)
    return nil unless @response_cookies
    @response_cookies.find { |c| c.name == name }
  end

end

# Override the default Context implementation
# to include methods useful for testing.

class Context
  attr_writer :session, :cookies
  
  def session
    @session || @session = {}
  end
  
  def cookies
    @cookies || @cookies = {}
  end
     
end

end

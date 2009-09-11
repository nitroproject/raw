require "raw/cgi/cookie"

module Raw

# Cookie related utility methods.

module CookieHelper

private

  def cookies
    @context.cookies
  end  

  # Send the cookie to the response stream.
  
  def send_cookie(name, value = nil)
    @context.add_cookie(name, value)
  end

  # Delete the cookie by setting the expire time to now and 
  # clearing the value.
  
  def delete_cookie(name)
    cookie = Cookie.new(name, "")
    cookie.expires = 1.year.ago  
    @context.add_cookie(cookie)    
  end
  
end

end

module Raw
  
# HTTP Response. This module is included in Context.

module Response

  # The Response status.

  attr_accessor :status

  # The Response headers.

  attr_accessor :response_headers

  # The Response cookies.

  attr_accessor :response_cookies

  # Return the content type for this response.
  
  def content_type
    @response_headers["Content-Type"]
  end

  # Set the content type for this response.
  
  def content_type=(ctype)
    @response_headers["Content-Type"] = ctype
  end

  # Add a cookie to the response. Better use this
  # method to avoid precreating the cookies array
  # for every request.
  #
  # A new cookie overrides previously set cookies.
  #
  # Examples:
  #
  #   add_cookie("nsid", "gmosx")
  #   add_cookie(Cookie.new("nsid", "gmosx")
  #
  #--
  # DESIGN: We use the hash to store the cookies to handle the 
  # override. Needed for example to delete cookies on logout.
  #++
  
  def add_cookie(cookie, value = nil)
    @response_cookies ||= {}

    if value
      @response_cookies[cookie] = Cookie.new(cookie, value)
    else 
      @response_cookies[cookie.name] = cookie
    end
  end
  alias_method :send_cookie, :add_cookie

  # Return the output buffer.
  
  def body
    @output_buffer
  end

end

end

module Raw

# Encapsulates a HTTP Cookie.

class Cookie
  attr_reader :name
  attr_accessor :value, :version
  attr_accessor :domain, :path, :secure
  attr_accessor :comment, :max_age

 def initialize(name = nil, value = nil, expires = nil)
    @name = name
    @value = value
    self.expires = expires
    @version = 0    # Netscape Cookie THINK: maybe should make this 1 ??
    @path = "/"     # gmosx: KEEP this!
    if false # Nitro.mode == :debug
      # This handles localhost, 127.0.0.1, 0.0.0.0 etc.
      @domain = Context.current.host
    else
      @domain = ".#{Context.current.domain(1)}" rescue nil # FIXME: This fucks up localhost domains, use 0.0.0.0 or 127.0.0.1 instead.
    end
    @secure = @comment = @max_age = nil
    @discard = @port = nil
  end

  # Set the cookie expiration.
  
  def expires=(t)
    @expires = t && (t.is_a?(Time) ? t.httpdate : t.to_s)
  end

  # When the cookie expires.
  
  def expires
    @expires && Time.parse(@expires)
  end
  
  def to_s
    str = "#{@name}=#{@value}"
    str << "; Version=#{@version}" if @version > 0
    str << "; Domain=#{@domain}" if @domain
    str << "; Expires=#{@expires}" if @expires
    str << "; Max-Age=#{@max_age}" if @max_age
    str << "; Comment=#{@comment}" if @comment
    str << "; Path=#{@path}" if @path
    str << "; Secure" if @secure
   
    return str
  end
  
  # Cookie equality.
  
  def == (other)
    @name == other.name
  end

end

end

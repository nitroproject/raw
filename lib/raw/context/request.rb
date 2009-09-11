module Raw
  
# Encapsulates a request. This is an abstract request
# typically extended by sub-classes. This module
# is included in Context.

module Request

  # The request input stream.

  attr_accessor :in

  # The request headers collection. Also called
  # the request environment (env).

  attr_accessor :headers
  alias_method :env, :headers
  alias_method :env=, :headers=
  alias_method :env_table, :headers

  attr_accessor :post_params
  attr_accessor :get_params

  # The parsed query parameters collection. This method 
  # integrates the get and post parameters in a single collection
  # and returns it as a Hash.
  #
  # If you need a Dictionary (ordered collection) use the lower
  # level post_params and get_params collection.
  
  def params
	  if method == :post
#		  @post_params.instance_variable_get("@hash")
		  @post_params
	  else
#		  @get_params.instance_variable_get("@hash")
		  @get_params
	  end
  end

  #--
  # THINK: is this needed / safe?
  #++
  
  def params=(pa)
	  if method == :post
		  @post_params = pa
	  else
		  @get_params = pa
	  end
  end

  alias_method :query, :params
  alias_method :parameters, :params
  
  # The request cookies.

  attr_accessor :cookies
  alias_method :cookie, :cookies

  # The request protocol.

  def protocol
    @headers["HTTPS"] == "on" ? "https://" : "http://"
  end

  # Is this an ssl request?

  def ssl?
    @headers["HTTPS"] == "on"
  end

  # The request uri.

  def uri
    @headers["REQUEST_URI"]
  end

  # The full uri, includes the host_uri.
  
  def full_uri
    "#{host_uri}#{uri}"
  end
  
  # The path info. Typically this is the rewritten uri without
  # the query string.
  
  def path_info
    @headers["PATH_INFO"]
  end
  alias_method :path, :path_info

  # Returns the domain part of a host.
  #
  # Examples:
  #
  #   www.nitroproject.org: request.domain # => 'nitroproject.org'
  #   www.nitroproject.co.uk: request.domain(2) # => 'nitroproject.co.uk'
  
  def domain(tld_length = 1)
    host.split(":").first.split(".").last(1 + tld_length).join(".")
  end

  # Returns all the subdomains as an array.
  #
  # Examples:
  # 
  #   my.name.nitroproject.org: request.subdomains # => ['my', 'name']
  
  def subdomains(tld_length = 1) 
    parts = host.split('.')
    parts[0..-(tld_length+2)]
  end

  # The request query string.

  def query_string 
    headers["QUERY_STRING"]
  end
  
  # The request method. Alternatively you could use the 
  # request method predicates.
  #
  # Examples:
  #
  #   if request.method == :get
  #   if request.get?

  def method
    @headers["REQUEST_METHOD"].downcase.to_sym
  end

  #--
  # Define a set of helpers to determine the request
  # method (get?, post?, put?, delete?, head?)
  #++
  
  for m in [:get, :post, :put, :delete, :head]
    eval %{
      def #{m}?; method == :#{m}; end
    }
  end

  # Determine whether the body of a POST request is URL-encoded 
  # (default), XML, or YAML by checking the Content-Type HTTP 
  # header:
  #
  #   Content-Type        Post Format
  #   application/xml     :xml
  #   text/xml            :xml
  #   application/x-yaml  :yaml
  #   text/x-yaml         :yaml
  #   *                   :url_encoded
  
  def post_format
    @post_format ||= if @headers['HTTP_X_POST_DATA_FORMAT']
      @headers['HTTP_X_POST_DATA_FORMAT'].downcase.to_sym
    else
      case @headers['CONTENT_TYPE'].to_s.downcase
      when "application/xml", "text/xml" then :xml
      when "application/x-yaml", "text/x-yaml" then :yaml
      else :url_encoded
      end
    end
  end

  # Is this a POST request formatted as XML or YAML?
  
  def formatted_post?
    post? && (post_format == :xml || post_format == :yaml)
  end

  # Is this a POST request formatted as XML?
  
  def xml_post?
    post? && post_format == :xml
  end

  # Is this a POST request formatted as YAML?
  
  def yaml_post?
    post? && post_format == :yaml
  end

  # Is this an XhtmlRpcRequest?
  # Returns true if the request's 'X-Requested-With' header 
  # contains 'XMLHttpRequest'. Compatible with the Prototype 
  # Javascript library.
  
  def xml_http_request?
    not /XMLHttpRequest/i.match(@headers['HTTP_X_REQUESTED_WITH']).nil?
  end
  alias_method :xhr?, :xml_http_request?
  alias_method :script?, :xml_http_request?
    
  # Return the referer. For the initial page in the
  # clickstream there is no referer, set "/" by default.
    
  def referer
    @headers["HTTP_REFERER"] || "/"
  end
  alias_method :referrer, :referer

  # The content_length
  
  def content_length
    @headers["CONTENT_LENGTH"].to_i
  end

  # The remote IP address. REMOTE_ADDR is the standard
  # but will fail if the user is behind a proxy.  
  # HTTP_CLIENT_IP and/or HTTP_X_FORWARDED_FOR are set by 
  # proxies so check for these before falling back to 
  # REMOTE_ADDR. HTTP_X_FORWARDED_FOR may be a comma-delimited 
  # list in the case of multiple chained proxies; the first 
  # is the originating IP.
                          
  def remote_ip
    return @headers['HTTP_CLIENT_IP'] if @headers.include?('HTTP_CLIENT_IP')

    if @headers.include?('HTTP_X_FORWARDED_FOR') then
      remote_ips = @headers['HTTP_X_FORWARDED_FOR'].split(',').reject do |ip|
        ip =~ /^unknown$/i or local_net?(ip)
      end

      return remote_ips.first.strip unless remote_ips.empty?
    end

    return @headers['REMOTE_ADDR']
  end

  # Request is from a local network? (RFC1918 + localhost)
  
  def local_net?(ip = remote_ip)
    bip = ip.split('.').map{ |x| x.to_i }.pack('C4').unpack('N')[0]

    # 127.0.0.1/32    => 2130706433
    # 192.168.0.0/16  => 49320
    # 172.16.0.0/12   => 2753
    # 10.0.0.0/8      => 10

    { 0 => 2130706433, 16 => 49320, 20 => 2753, 24 => 10}.each do |s,c|
       return true if (bip >> s) == c
    end
    
    return false
  end
  
  # Request comming from local?
  
  def local?(ip = remote_ip)
    # TODO: should check if requesting machine is the one the server is running
    return true if ip == '127.0.0.1'
  end

  # The server port.

  def port
    @headers['SERVER_PORT'].to_i
  end

  # The server host name.
  # Also handles proxy forwarding.

  def host
    @headers['HTTP_X_FORWARDED_HOST'] || @headers['HTTP_HOST'] 
  end

  # The host uri.
  
  def host_uri
    "#{protocol}#{host}"
  end
  alias_method :server_uri, :host_uri
  # This is deprecated.
  alias_method :host_url, :host_uri

  # Different servers hold user agent in differnet 
  # strings (unify this).
  
  def user_agent
    headers["HTTP_USER_AGENT"] || headers["USER-AGENT"]
  end

  # The raw data of the request.
  # Useful to implement Webservices.
  #--
  # FIXME: better name and implementation.
  #++

  def raw_body
    unless @raw_body
      @in.rewind
      @raw_body = @in.read(content_length)
    end

    @raw_body
  end
  
  # Lookup a query parameter.
  #--
  # TODO: Check if unescape is needed.
  #++
  
  def [](param)
    params[param.to_s]
  end

  # Set a query parameter.

  def []=(param, value)
    params[param.to_s] = value
  end
  
  # Check if a boolean param (checkbox) is true.
  
  def true?(param)
    params[param] == 'on'
  end
  alias_method :enabled?, :true?
  alias_method :boolean, :true?
  
  # Check if a boolean param (checkbox) is false.
   
  def false?(param)
    !true?(param)
  end
  
  # Fetch a parameter with default value.
  
  def fetch(param, default = nil)
    params[param] || default
    # gmosx: I *think* facets fucks-up the fetch implementation.
    # params.fetch(param, default)
  end
  
  # Check if a param is available.
  #--
  # gmosx: use instead of nil test to be more robust.
  # (nil can be a hash element !)
  #++
    
  def has_key?(key)
    params.keys.include?(key)
  end
  alias_method :has_param?, :has_key?
  alias_method :param?, :has_key?
  alias_method :has?, :has_key?
  alias_method :is?, :has_key?
  
  def keys
    params.keys
  end
  
end

end

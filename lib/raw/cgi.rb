require "cgi"
require "yaml"
require "stringio"

begin
  require "xmlsimple"
rescue LoadError => e
  $stderr.puts "Install XMLSimple (sudo gem install xml-simple) for XML input."
end

require "facets/settings"

require "blow/json"

require "raw/cgi/http"

module Raw

# Nitro CGI (Common Gateway Interface) methods. Typically 
# handles HTTP Request parsing and HTTP Response generation.

class Cgi
  include Http

  # Maximum content length allowed in requests.

  setting :max_content_length, :default => (2 * 1024 * 1024), :doc => 'Maximum content length allowed in requests'

  # Multipart parsing buffer size.

  setting :buffer_size, :default => (10 * 1024), :doc => 'Multipart parsing buffer size'

  # Push a parameter into the params hash
  # gmosx: We don't allow xxx.yyy style of structured params
  # (due to some incompatibilities with libraries), please
  # only use xxx[yyy] params.

  def self.structure_param(params, key, val)
    if key =~ /(.+)\[(.+)\]$/
      # This should be a Dictionary to preserve ordering for
      # Controller.mixin_get_parameters
      params[$1] ||= {}
      params[$1] = structure_param(params[$1], $2, val)
    elsif key =~ /(.+)\[\]$/
      params[$1] ||= []
      params[$1] << val.to_s
    else
      params[key] = val.nil? ? nil : val
    end
    
    return params
  end

  # Returns a hash with the pairs from the query string. The 
  # implicit hash construction that is done in parse_request_params 
  # is not done here.
  
  def self.parse_query_string(query_string)
#    params = Dictionary.new
    params = {}
    
    # gmosx, THINK: better return nil here?
    return params if (query_string.nil? or query_string.empty?)

    query_string.split(/[&;]/).each do |p| 
      key, val = p.split("=")
      
      key = CGI.unescape(key) unless key.nil?
      val = CGI.unescape(val) unless val.nil?
      
      params = self.structure_param(params, key, val)
    end
    
    return params
  end

  # Parse the HTTP_COOKIE header and returns the
  # cookies as a key->value hash. For efficiency no 
  # cookie objects are created.
  #
  # [+context+]
  #    The context 

  def self.parse_cookies(context)
    env = context.env

    # FIXME: dont precreate?
    context.cookies = {}

    if env["HTTP_COOKIE"] or env["COOKIE"]
      (env["HTTP_COOKIE"] or env["COOKIE"]).split(/; /).each do |c|
        key, val = c.split(/=/, 2)
        val ||= ""
        key = CGI.unescape(key)
        val = val.split(/&/).collect{|v| CGI.unescape(v)}.join("\0")
        if context.cookies.include?(key)
          context.cookies[key] += "\0" + val
        else
          context.cookies[key] = val
        end
      end
    end
  end

  # Build the response headers for the context. 
  #
  # [+context+]
  #    The context of the response.
  #
  # [+proto+]
  #    If true emmit the protocol line. Useful for MOD_RUBY.
  #--
  # FIXME: return the correct protocol from env.
  # TODO: Perhaps I can optimize status calc.
  #++
                                                                                      
  def self.response_headers(context, proto = false)
    reason = STATUS_STRINGS[context.status] 

    if proto
      buf = "HTTP/1.1 #{context.status} #{reason}#{EOL}Date: #{CGI::rfc1123_date(Time.now)}#{EOL}"
    else
      buf = "Status: #{context.status} #{reason}#{EOL}"
    end

    context.response_headers.each do |key, value|
      tmp = key.gsub(/\bwww|^te$|\b\w/) { |s| s.upcase }
      buf << "#{tmp}: #{value}" << EOL
    end
  
    context.response_cookies.values.each do |cookie|
      buf << "Set-Cookie: " << cookie.to_s << EOL
    end if context.response_cookies
      
    buf << EOL

    return buf
  end
  
  # Initialize the request params.
  # Handles multipart forms (in particular, forms that involve 
  # file uploads). Reads query parameters in the @params field, 
  # and cookies into @cookies.
  
  def self.parse_params(context)
    context.get_params = parse_query_string(context.query_string)  

    if :post == context.method
      if %r|\Amultipart/form-data.*boundary=\"?([^\";,]+)\"?|n.match(context.headers["CONTENT_TYPE"])
        boundary = $1.dup
        context.post_params = parse_multipart(context, boundary)
      else
        context.in.binmode if defined?(context.in.binmode)
        data = context.in.read(context.content_length) || ""

        case context.headers["CONTENT_TYPE"]
        when "application/xml" && defined?(XmlSimple)
          context.post_params = XmlSimple.xml_in(data, "keeproot" => true)
        when "application/json"
          context.post_params = JSON.parse(data)
        when "application/yaml"
          context.post_params = YAML.load(data)
        else # query string  
          context.post_params = parse_query_string(data)  
        end
      end
    end
  end

  # Parse a multipart request.
  # Adapted from Ruby's cgi.rb
  #--
  # TODO: RECODE THIS CRAP!
  #++

  def self.parse_multipart(context, boundary)
    input = context.in
    content_length = context.content_length
    env_table = context.env
    
    params = {}
    
    boundary = "--" + boundary
    quoted_boundary = Regexp.quote(boundary, "n")
    buf = ""
    boundary_end=""
    
    # start multipart/form-data
    input.binmode if defined? input.binmode
    boundary_size = boundary.size + EOL.size
    content_length -= boundary_size
    status = input.read(boundary_size)

    if nil == status
      raise EOFError, "no content body"
    elsif boundary + EOL != status
      raise EOFError, "bad content body"
    end

    loop do
      head = nil

      if 10240 < content_length
        body = Tempfile.new("CGI")
      else
        begin
          require "stringio"
          body = StringIO.new
        rescue LoadError
          body = Tempfile.new("CGI")
        end
      end
      body.binmode if defined? body.binmode

      until head and /#{quoted_boundary}(?:#{EOL}|--)/n.match(buf)

        if (not head) and /#{EOL}#{EOL}/n.match(buf)
          buf = buf.sub(/\A((?:.|\n)*?#{EOL})#{EOL}/n) do
            head = $1.dup
            ""
          end
          next
        end

        if head and ( (EOL + boundary + EOL).size < buf.size )
          body.print buf[0 ... (buf.size - (EOL + boundary + EOL).size)]
          buf[0 ... (buf.size - (EOL + boundary + EOL).size)] = ""
        end

        c = if Cgi.buffer_size < content_length
              input.read(Cgi.buffer_size)
            else
              input.read(content_length)
            end
        if c.nil? || c.empty?
          raise EOFError, "bad content body"
        end
        buf.concat(c)
        content_length -= c.size
      end

      buf = buf.sub(/\A((?:.|\n)*?)(?:[\r\n]{1,2})?#{quoted_boundary}([\r\n]{1,2}|--)/n) do
        body.print $1
        if "--" == $2
          content_length = -1
        end
        boundary_end = $2.dup
        ""
      end

      body.rewind

      /Content-Disposition:.* filename="?([^\";]*)"?/ni.match(head)
      
      filename = ($1 or "")

      if /Mac/ni.match(env_table['HTTP_USER_AGENT']) and
          /Mozilla/ni.match(env_table['HTTP_USER_AGENT']) and
          (not /MSIE/ni.match(env_table['HTTP_USER_AGENT']))
        filename = CGI::unescape(filename)
      end
      
      /Content-Type: (.*)/ni.match(head)
      content_type = ($1 or "")

      (class << body; self; end).class_eval do
        alias_method :local_path, :path
        define_method(:original_filename) { filename.dup.taint }
        define_method(:content_type) { content_type.dup.taint }

        # gmosx: this hides the performance hit!!
        define_method(:to_s) { str = read; rewind; return str}
      end

      /Content-Disposition:.* name="?([^\";]*)"?/ni.match(head)
      name = $1.dup
      
      params = self.structure_param(params, name, body)

      break if buf.size == 0
      break if content_length === -1
    end
    raise EOFError, "bad boundary end of body" unless boundary_end =~ /--/

    return params
  end
  
end
  
end

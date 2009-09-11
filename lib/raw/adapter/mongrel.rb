require "stringio"

require "mongrel"
require "mongrel/handlers"

require "raw/adapter"

#--
# Customize Mongrel to make compatible with Nitro.
#++

module Mongrel # :nodoc: all

  class HttpRequest
    def method_missing(name, *args)
      if @params.has_key?(name.to_s.upcase)
        return @params[name.to_s.upcase]
      elsif name.to_s =~ /\A(.*)=\Z/ && @params.has_key?($1.upcase)
        @params[$1.upcase] = args[0]
      else
        super
      end
    end
  end

end

module Raw

# A Mongrel Adapter.
#
# Mongrel is a fast HTTP library and server for Ruby that is 
# intended for hosting Ruby web applications of any kind using 
# plain HTTP rather than FastCGI or SCGI. 
#
# This is the preferred adapter for production Nitro 
# applications.

class MongrelAdapter < Adapter

  def start(application)
    super
    
    @mongrel = Mongrel::Configurator.new(:host => application.address) do
      listener(:port => application.port) do
        uri "/", :handler => MongrelHandler.new(application)
        trap("INT") { stop(application) }
        run
      end
    end

    @mongrel.join()
  end
  
  def stop
    super
    @mongrel.stop()
  end

end

# The Mongrel Handler, handles an HTTP request.

class MongrelHandler < Mongrel::HttpHandler
  include AdapterHandlerMixin
  
  def initialize(application)
    @application = application
  end
  
  # Handle a static file. Also handles cached pages. Typically
  # *not* used in production applications.

  def handle_file(req, res)
    return false unless @application.handle_static_files    

    filename = File.join(@application.public_dir, req.path_info).squeeze("/")

    File.open(filename, "rb") do |f|
      # TODO: check whether path circumvents public_root directory?
      res.status = 200
      res.body << f.read # XXX inefficient for large files, may cause leaks
    end
    
    return true
  rescue Errno::ENOENT => ex # TODO: Lookup Win32 error for 'file missing'
    return false
  end

  # Handle the request.
  #--
  # TODO: recode this like the camping mongrel handler.
  #++
  
  def process(req, res)
    # Perform default rewriting rules.
    
    rewrite(req)

    # First, try to serve a static file from disk.

    return if handle_file(req, res)

    context = Context.new(@application)

    if req.body.is_a? String
      context.in = StringIO.new(req.body)
    else
      context.in =   req.body
    end

    context.headers = {}
    req.params.each { |h, v|
      if h =~ /\AHTTP_(.*)\Z/
        context.headers[$1.gsub("_", "-")] = v
      end
      context.headers[h] = v
    }
    
    # hackfix: make it behave like webrick and fcgi
    # context.headers["REQUEST_URI"] << "?#{context.headers['QUERY_STRING']}" if context.headers["QUERY_STRING"]
    context.headers["QUERY_STRING"] ||= ""

    output = handle_context(context)

    # THINK: what is the error code if a request without a handler 
    # is comming?!
    
    res.start(context.status, true) do |head, out|
      context.response_headers.each do |key, value|
        head[key] = value
      end
      
      context.response_cookies.values.each do |cookie|
        head["Set-Cookie"] = cookie
      end if context.response_cookies
      
      out.write(output)
    end
  end  
  
end

end

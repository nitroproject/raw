require "stringio"
require "webrick"

require "raw/adapter"

module Raw

# A Webrick Adapter for Nitro. Webrick is a pure Ruby web server
# included in the default Ruby distribution. The Webrick Adapter
# is the prefered adapter in development/debug environments. It
# is also extremely easy to setup.
#
# However, for live/production environments, you should prefer
# a more performant adapter like Mongrel or FCGI. Mongrel is the
# suggested adapter for production applications.

class WebrickAdapter < Adapter

  class Swallow # :nodoc: all
    def self.method_missing(*args)
      # drink it!
    end
  end

  # Start the adapter.
  
  def start(app)
    super
    
    if RUBY_PLATFORM !~ /mswin32/
      wblog = WEBrick::BasicLog::new("/dev/null")
    elsif File.exist? "log"
      wblog = WEBrick::BasicLog::new("log/access.log")
    else
      wblog = STDERR
    end

    webrick_options = app.options.dup
    
    require "webrick/https" if webrick_options[:SSLEnable]

    webrick_options.update(
      :BindAddress => app.address, 
      :Port => app.port, 
      :DocumentRoot => app.public_dir,
      :Logger => Swallow,
      :AccessLog => [
        [wblog, WEBrick::AccessLog::COMMON_LOG_FORMAT],
        [wblog, WEBrick::AccessLog::REFERER_LOG_FORMAT]
      ]
    )

    trap("INT") { stop }
    
    @webrick = WEBrick::HTTPServer.new(webrick_options)
    @webrick.mount("/", WebrickHandler, app)
    @webrick.start
  end
  
  # Stop the adapter.
  
  def stop
    super
    @webrick.shutdown
  end

end

# The Webrick Handler, handles an HTTP request.
#--
# TODO: add some way to prevent the display of template files
# if the public dir is used as the template dir.
#++

class WebrickHandler < WEBrick::HTTPServlet::AbstractServlet
  include WEBrick
  include AdapterHandlerMixin

  def initialize(webrick, app)
    @application = app

    # Handles static resources. Useful when running 
    # a stand-alone webrick server.

    @file_handler = WEBrick::HTTPServlet::FileHandler.new(
      webrick, app.public_dir, app.options
    )
  end

  # Handle a static file. Also handles cached pages. Typically
  # *not* used in production applications.
  
  def handle_file(req, res)
    return false unless @application.handle_static_files    
    temp = req.path_info
    @file_handler.do_GET(req, res)
    return true
  rescue WEBrick::HTTPStatus::PartialContent, WEBrick::HTTPStatus::NotModified => err
    res.set_error(err)
    return true
  rescue WEBrick::HTTPStatus::NotFound => ex
    return false
  ensure
    req.path_info = temp
  end

  # Handle the request.

  def handle(req, res)
    # Perform default rewriting rules.
    
    rewrite(req)

    # First, try to serve a static file from disk.

    return if handle_file(req, res)

    # No static file found, attempt to dynamically generate 
    # a response.
    
    context = Context.new(@application)

    context.in = StringIO.new(req.body || "")

    context.headers = {}
    req.header.each { |h, v| context.headers[h.upcase] = v.first }
    context.headers.update(req.meta_vars)

    # gmosx: make compatible with fastcgi.
      
    context.headers["REQUEST_URI"].slice!(/http:\/\/(.*?)\//)
    context.headers["REQUEST_URI"] = "/" + context.headers["REQUEST_URI"]

    res.body = handle_context(context)
    
    res.status = context.status
    res.instance_variable_set(:@header, context.response_headers || {})
    if context.response_cookies
      res.instance_variable_set(:@cookies, context.response_cookies.values)
    end
  end

  alias_method :do_GET, :handle 
  alias_method :do_POST, :handle

end

end

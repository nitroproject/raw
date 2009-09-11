require "cgi"
require "socket"

require "facets/stylize"
#require "facets/string/demodulize"
#require "facets/string/underscore"
#require "facets/string/humanize"

require "raw/cgi"

# Speeds things up, more compatible with OSX.

Socket.do_not_reverse_lookup = true

module Raw

# The base Adapter class. All other adapters extend this class.
# An adapter conceptually connects Nitro with a Front Web Server.
# Please notice that many Adapters (for example Webrick and
# Mongrel implement an 'inline' Front Web Server).
#
# The Adapter typically initializes a Handler to handle the
# http requests. 

class Adapter
  
  # Initialize the adapter.
  
  def initialize
  end

  # Setup the adapter (used as a hook).
  
  def setup(app)
  end
  
  # Start the adapter.
  
  def start(app)
    info "Press Ctrl-C to shutdown; Run with --help for options."

    setup(app)
  end
  
  # Stop the adapter.
  
  def stop
    info "Stoping server."
  end
  
end

# This mixin provides default functionality to adapter handlers.

module AdapterHandlerMixin

  # Handle a context. Returns the generated output.
  
  def handle_context(context)
    Cgi.parse_params(context)
    Cgi.parse_cookies(context)    
    
    controller_class, action, query, params, context.format = @application.dispatcher.dispatch_context(context)
    context.content_type = context.format.content_type
    
    Thread.current[:CURRENT_CONTROLLER] = controller_class
    controller = controller_class.new(context)

    controller.send(:render_action, action, params)

  rescue => ex
    error "Error while handling '#{context.uri}'"
    error pp_exception(ex)
    
  ensure      
    context.close
    return controller.out # context.output_buffer <-- Why doesn't it work?
   end
  
  # Try to rewrite the path to a filename.

  def rewrite(req)
    if req.path_info == "/"
      req.path_info = "/index.html" 
    elsif req.path_info =~ /^([^.]+)$/
      req.path_info = "#{$1}.html" 
    end
  end

  # Rewrite back to the original path.

  def unrewrite(req)
    if req.path_info == "/index.html"
      req.path_info = "/" 
    elsif req.path_info =~ /^([^.]+)\.html$/    
      req.path_info = $1 
    end
  end

end


end

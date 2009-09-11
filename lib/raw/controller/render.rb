require "stringio"

require "facets/string/blank"
require "facets/settings"

require "raw/view/builder"
require "raw/controller/call"

module Raw

#--
# The output buffer. The output of a contoller action is
# accumulated in this buffer before sending this to the client
# as a HTTP Response.
#
# TODO: Implement a FAST string (maybe in C)
#++

class OutputBuffer < String # :nodoc: all
end

# The rendering mixin. This module is typically included in
# published objects and/or controllers to provide rendering
# functionality.

module Render

  # The output buffer. The output of a script/action is 
  # accumulated in this buffer.
  
  attr_accessor :out  
  alias_method :body, :out
    
  # The context.
  
  attr_accessor :context
  alias_method :request, :context
  alias_method :response, :context
    
  # The name of the currently executing action.

  attr_accessor :action_name

  # The current controller class.
  
  attr_accessor :controller
  
  # Initialize the render.
  #
  # [+context+]
  #    A parent render/controller acts as the context.

  def initialize(context)
    @context = context
    @out = context.output_buffer
  end

private

  # Renders the action denoted by path. The path
  # is resolved by the dispatcher to get the correct
  # controller.
  #
  # Both relative and absolute paths are supported. Relative
  # paths are converted to absolute by prepending the mount path
  # of the controller.
  
  def render(*args)
    path = encode_uri(*args)

    debug "Rendering '#{path}'" if $DBG
  
    @controller_class, action, query, params, @context.format = @context.dispatcher.dispatch(path)
#    @context.content_type = @context.format.content_type

    @context.level += 1
    old_controller_class = Controller.replace_current(@controller_class)
    
    if self.class == @controller_class 
      render_action(action, params)
    else
      @controller_class.new(@context).send(:render_action, action, params)
    end

    Controller.replace_current(old_controller_class)
    @context.level -= 1
  end

  # Perform the actual action rendering.
  
  def render_action(action, params)
    send(action, params)
    
  rescue RenderExit, ActionExit => e1
    # Just stop rendering.     
    
  rescue ActionError => e2
    # Client Error family of errors, typically send 4XX
    # status code.
    handle_error(e2, 404)
    error e2.to_s
        
  rescue Object => e3
    # Server Error family of errors, typically send 5XX
    # status code.    
    handle_error(e3, 500)
    error "Error while handling #{self.class}##{action.to_s.gsub(/___super$/, '')}(#{params.join(', ')})"
    error pp_exception(e3)
  end

  RADIUS = 3

  # Extract the offending source code for a server error.
  
  def extract_source_from(error)
    extract = []
    
    code = error.backtrace[1]
    md = code.match(%r{:(\d+):in `(.*)'$})
    line_num = md[1].to_i

    if lines = code.split("\n")[(line_num - RADIUS)..(line_num + RADIUS)]
      lines.each_with_index do |line, idx|
        lidx = line_num - RADIUS + idx 
        extract << "#{lidx}: #{line}"
      end    
    end
        
    return extract
  end

  # Helper method to exit the current action, typically used
  # to skip the template rendering.
  # 
  # === Example
  #
  # def my_action
  #   ...
  #   exit unless user.admin?
  # end
  
  def exit
    raise ActionExit.new
  end

  # Flush the IO object (OutputBuffer) if we are in streaming 
  # mode.
  
  def flush
    @out.flush if @out.is_a?(IO)
  end

  # :section: Redirection methods.

  # Send a redirect response.
  #
  # If the URI (path) starts with '/' it is considered absolute, else
  # the URI is considered relative to the current controller and
  # the controller base is prepended.
  #
  # The parameters are passed to the R operator (encode_uri)
  # to actually build the URI. So the following forms (among
  # others) are allowed:
  #
  # redirect 'home/login'
  # redirect ForaController, :post, :title, 'The title'
  # redirect :welcome
  # redirect article # => article.to_href
  #
  # You can also pass optional hash parameters at the end,
  # for example:
  #
  # redirect :welcome, :status => 307
  #
  # The default redirect status is 303.
  #
  #--
  # TODO: add a check for redirect to self (infinite loop)
  #++
  
  def redirect(*args)
    # If this is an ajax  and/or rpc request skip the redirect.
    # Allows to write more reusable  code.

    return if  request.script?
  
    if args.last.is_a? Hash
      status = args.last.fetch(:status, 303)
    else
      status = 303
    end

    uri = encode_uri(*args)

    # gmosx, THINK: this may be unnecessary!

    unless uri =~ /^http/
      uri = "#{@context.host_uri}/#{uri.gsub(/^\//, '')}"
    end

    @context.status = status
    @out = "<html><a href=\"#{uri}\">#{uri}</a>.</html>\n"
    @context.response_headers['location'] = uri

    raise RenderExit
  end
  alias_method :redirect_to, :redirect
  
  # Redirect to the referer.
  
  def redirect_referer(postfix = nil, status = 303)
    redirect "#{@context.referer}#{postfix}", :status => status
  end
  alias_method :redirect_to_referer, :redirect_referer
  alias_method :redirect_referrer, :redirect_referer
  alias_method :redirect_to_referrer, :redirect_referer

  # Redirect to home.
  
  def redirect_home(status = 303)
    redirect "/", :status => status
  end
  alias_method :redirect_to_home, :redirect_home

  # Handle an error.
  #--
  # gmosx, TODO: add check for infinite loops here.
  #++
   
  def handle_error(exception, error_status = 500)
    unless @context.status == error_status
      @context.status = error_status
      
      # FIXME: have to reset @context as well. This is uggly 
      # and extremely error prone. We should rethink how this 
      # works.
      
      @out = @context.output_buffer = ""

      session[:RENDERING_ERROR] = exception

      render("/status_#{error_status}")
    end
  end

  # Convenience method to lookup the session.

  def session
    @context.session
  end
  
  # Add some text to the output buffer.

  def render_text(text)
    @out << text
  end
  alias_method :print, :render_text

  # Render a template into the output buffer.
  # HACK FIX, will be removed.
  
  def render_template(path)
    render(path)
    exit
  end
  alias_method :template, :render_template

end

end

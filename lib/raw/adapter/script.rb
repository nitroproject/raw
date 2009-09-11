require "raw/adapter"

module Raw

# The script adapter. Useful when running in console mode, or
# when creating scripts for cron jobs, testing and more. Allows
# you to programmatically 'drive' the web application.

class ScriptAdapter < Adapter
  include AdapterHandlerMixin

  # The last generated response.
  
  attr_accessor :response
  
  def start(application)
    info "This console  is attached to the application context."
    info ""
    info "* $app points to the application"
    info "* $srv points to the adapter"
    info "* use get(uri), post(uri), response() to programmatically call actions"
    info ""
    
    $app = $application = @application = application
    $srv = $adapter = self
  end
  
  # Perform a programatic http request to the web app.
  #
  # === Examples
  #
  # $srv.get 'users/logout'
  # $srv.post 'users/login', :params => { :name => 'gmosx', :password => 'pass' }
  # $srv.post 'users/login?name=gmosx;password=pass
  # $srv.post 'articles/view/1'
  
  def handle(uri, options = {})
    # Perform default rewriting rules.

    path_info = uri

    if path_info == "/"
      path_info = "/index.html" 
    elsif path_info =~ /^([^.]+)$/
      path_info = "#{$1}.html" 
    end

    context = Context.new(@application)
    
    context.get_params = options.fetch(:get_params, {})
    context.post_params = options.fetch(:post_params, {})
    context.headers = options.fetch(:headers, {})
 
    context.headers["REQUEST_URI"] = uri
    context.headers["PATH_INFO"] = path_info
    context.headers["REQUEST_METHOD"] = options.fetch(:method, :get)
    context.headers["HTTP_COOKIE"] ||= options[:cookies]
          
    handle_context(context)
  
    @response = context

    return context
  end
  
  # Perform a programmatic http get request to the web app.
   
  def get(uri, options = {})
    options[:method] = "get"
    handle(uri, options)
  end

  # Perform a programmatic http post request to the web app.
   
  def post(uri, options = {})
    options[:method] = "post"
    handle(uri, options)
  end
    
end

end

# Add some convienience methods.

if ENV["NITRO_ADAPTER"] == "script"

def get(*args)
  $srv.get(*args)
end

def post(*args)
  $srv.post(*args)
end

def response
  $srv.response
end

end

module Raw

# A collection of intelligent uri encoding methods.

module EncodeURI

private

  # Encode controller, action, params into a valid url.
  # Automatically respects nice urls and routing.
  #
  # Handles parameters either as a hash or as an array.
  # Use the array method to pass parameters to 'nice' actions.
  #
  # Pass Controller, action, and (param_name, param_value) 
  # pairs.
  #
  # If you pass an entity (model) class as the first parameter,
  # the encoder tries to lookup the default controller for this
  # class (ie, Klass::Controller).
  #
  # === Examples
  #
  # encode_uri ForaController, :post, :title, 'Hello', :body, 'World'
  # encode_uri :post, :title, 'Hello', :body, 'World' # => implies controller == self
  # encode_uri :kick, :oid, 4
  # encode_uri article # => article.to_href
  # 
  # Alternatively you can pass options with a hash:
  #
  # encode_uri :controller => ForaController, :action => :delete, :params => { :title => 'Hello' }
  # encode_uri :action => :delete
  #--
  # Design: The pseudo-hack method with the alternating array 
  # elements is needed because Ruby hashes are not sorted.
  # FIXME: better implementation? optimize this?
  # TODO: move elsewhere.
  #++
  
  def encode_uri(*args)
    f = args.first
    
    # A standard uri as string, return as is.
    
    if f.is_a? String
      # Attach the controller mount_path if this is a relative
      # path. Use Controller.current to make this method more
      # reusable.
      unless f =~ /^\// or f =~ /^http/
        f = "#{Controller.current.mount_path}/#{f}" # .squeeze("/") # <-------------- FIXME: REMOVE!!  
      end
      return f
    end
  
    # If the passed param is an object that responds to :to_href
    # returns the uri to this object.

    if f.respond_to?(:to_href) and (args.size == 1)
      return f.to_href
    end
    
    if f.is_a? Symbol
      # no controller passed, try to use self as controller.
      if self.class.respond_to? :mount_path
        args.unshift(self.class)
      else
        raise "No controller passed to encode_uri"
      end
    end

    # Try to encode using the router.
    
    if router = Context.current.dispatcher.router
      if path = router.encode_route(*args)
        return path
      end
    end
    
    # No routing rule, manual encoding.
    
    controller = args.shift
    
    unless args.empty?
      action = args.shift.to_sym
    else
      action = :index
    end

    if controller.is_a? Class
      # If the class argument is not a controller, try to get 
      # a controller for this class.
      
      unless controller.respond_to? :mount_path
        # Use the standard controller convention.
        controller = controller::Controller
      end
    else
      # An entity model is passed, lookup the class, then 
      # the controller and inject the oid as a parameter. For
      # example:
      #
      # a = Article[1]
      # encode_uri(a, :read) == encode_uri(Article::Controller, :read, :oid, a.oid)
      
      args.unshift :oid, controller.oid
      controller = controller.class::Controller
    end
    
    if action == :index
      uri = "#{controller.mount_path}"
    else
      mount_path = controller.mount_path
#      mount_path = nil if mount_path == "/" FIXME: remove!    
      uri = "#{mount_path}/#{action}"
    end

    unless args.empty?
      if controller.action_or_template?(action, Context.current.format)
        param_count = controller.instance_method(action).arity
        if param_count > 0
           param_count.times do
            args.shift # name 
            uri << "/#{CGI.escape(args.shift.to_s)}"
          end        
        end
      end
      
      unless args.empty?
        uri << "?"
        params = []
        (args.size / 2).times do
          params << "#{args.shift}=#{args.shift}" 
        end
        uri << params.join(';')
      end
    end
    
    return uri  
  end
  alias R encode_uri
  alias encode_url encode_uri # DEPRECATED.
  

  # Just like encode_uri, but generates an absolute URI instead.
  
  def encode_absolute_uri(*args)
    return "#{request.host_uri}#{encode_uri(*args)}"
  end
  alias RA encode_absolute_uri
  alias encode_absolute_url encode_absolute_uri # DEPRECATED.
  
end

class TemplateFilter
  include EncodeURI
end

end

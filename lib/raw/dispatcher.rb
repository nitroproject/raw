require "facets/kernel/constant"
require "facets/module/ancestor"

require "raw/dispatcher/router"
require "raw/dispatcher/mounter"
require "raw/dispatcher/format"

require "raw/controller/publishable"

module Raw

# The Dispatcher manages a set of controllers. It selects the
# appropriate Controller and action to handle the given
# request.
#
# This dispatcher intelligently handles RESTful uris according
# to the following scheme:
#
# GET    /links             GET  /links/index     Link::Controller#index
# POST   /links             POST /links/create    Link::Controller#create
# GET    /links;new         GET  /links/new       Link::Controller#new
# GET    /links/1                                 Link::Controller#view(1)
# GET    /links/1;edit      GET  /links/edit/1    Link::Controller#edit(1)
# PUT    /links/1           POST /links/update/1  Link::Controller#update
# DELETE /links/1           GET  /links/delete/1  Link::Controller#delete(1)
# GET    /links/index.xml                         Link::Controller#index # Atom
# GET    /links/index.json                        Link::Controller#index # JSON
#
# The default actions for the various methods are:
#
#    GET: index
#   POST: create
#    PUT: update
# DELETE: delete

class Dispatcher

  # The (optional) router.

  attr_accessor :router

  # The hash that maps mount paths to controllers.

  attr_accessor :controllers

  # The representation formats this dispatcher understands.

  attr_accessor :formats

  # Initialize the dispatcher.

  def initialize(controller_or_map = nil)
    @controllers = {}
    @formats = STANDARD_FORMATS.dup

    if controller_or_map.is_a?(Class)
      mount("" => controller_or_map)
    elsif controller_or_map.is_a?(Hash)
      mount(controller_or_map)
    end
  end

  # Mounts a map of controllers.

  def mount(map)
    for path, controller in map
      self[path] = controller
    end
  end

  # Return the controller for the given mount path. Please note
  # that the root path is "".
  #
  # Example:
  #   disp[""]

  def [](path = "")
    @controllers[path]
  end

  # Mount a controller to the given mount path. Please note
  # that the root path is "".
  #
  # If you pass a model class to this method it automatically
  # tries to mount the default controller, ie
  # YourModel::Controller (for the YourModel model).
  #
  # Example:
  #   disp[""] = RootController
  #   disp["/articles"] = Article::Controller
  #   disp["/articles"] = Article # same as above.
  #

  def []=(path, controller)
    controller = resolve_controller(controller)

    # Customize the class for mounting at the given path.
    controller.mount_at(path) if controller.respond_to? :mount_at

    # Call the mounted callback to allow for post mount
    # initialization.
    controller.mounted(path) if controller.respond_to? :mounted

    @controllers[path] = controller
  end

  # Return the mounted controllers.

  def mounted_controllers
    @controllers.values
  end

  # Dispatch a request. Calls the lower level dispatch method.

  def dispatch_request(request)
    dispatch(request.uri, request.method)
  end
  alias_method :dispatch_context, :dispatch_request

  # Dispatch a path given the request method. This method
  # handles fully resolved paths (containing an extension that
  # denotes the expected content type).
  #
  # This method automatically handles 'nice' (seo friendly,
  # elegant) parameters, ie:
  #
  #   /links/view/1
  #
  # instead of
  #
  #   /links/view?oid=1
  #
  # Please note that the dispatch accepts a standard path,
  # ie the root path is "/" and not "".
  #
  # Output:
  #   controller, action, query_string, nice_params, extension
  #--
  # Lower level, useful for testing.
  #++

  def dispatch(uri, method = :get)

    debug "Dispatching #{uri}" if $DBG

    # Extract the query string.

    path, query = uri.split("?", 2)
    path ||= ""

    # Remove trailing '/' that fucks up the dispatching
    # algorithm.

    path.gsub!(%r{/$}, "")

    # Try to route the path.

    path = @router.route(path) if @router

    # The characters after the last '.' in the path form the
    # extension that itself represents the expected response
    # content type.

    ext = File.extname(path)[1..-1] || "html"

    # The resource representation format for this request.

    if format = @formats.by_extension[ext]
      # Remove the extension from the path.
      path = path.gsub(/\.(.*)$/, "")
    else
      # gmosx: Don't raise exception, just pass the latest part
      # as a parameter.
      # raise ActionError.new("Cannot respond to '#{path}' using the '#{ext}' format representation.")
      format = @formats.by_extension["html"]
    end

    # Try to extract the controller from the path (that may also
    # include 'nice' parameters). This algorithm tries to find
    # the bigest substring of the path that represents a mount
    # path for a controller.

    key = path.dup

    while (controller = @controllers[key]).nil?
      key = key[%r{^(/.+)/.+$}, 1] || ""
    end

    # Try to extract the action from the path. This
    # algorithm tries to find the bigest substring of the path
    # that represents an action of this controller.
    #
    # The algorithm respects action name conventions, ie
    # simple/sub/action maps to simple__sub__action.

    action = key = path.sub(%r{^#{key}}, '').gsub(%r{^/}, '').gsub(%r{/}, '__')

    while (!action.blank?) and !controller.action_or_template?(action, format)
      # gmosx: the final '_' fixes a bug user/view/_xxx_
      action = action[/^(.+)__.+$/, 1]
      action.gsub!(/_$/, "") if action
    end
    
    # Extract the 'nice' parameters.

    params = key.sub(%r{^#{action}}, '').gsub(/^__/, '').split('__')

    # Do we have an action?

    if action.blank?
      # Try to use a standard action for this http method.
      #--
      # FIXME: this is dangerous if we want to handle a post
      # method from an index (blank) action. Only perform this
      # on 'API' calls.
      #++
=begin
      case method
        when :get
          action = "index"

        when :post
          action = "create"

        when :delete
          action = "delete"

        when :put
          action = "update"
      end
=end
      action = "index"

      unless controller.action_or_template?(action, format)
        # raise ActionError.new("Cannot respond to '#{path}' (action: #{action}) using '#{controller}'")
      end
    end

    # Pad the 'nice' parameters with nil values.

    if (ar = controller.instance_method(action).arity) > 0
      params.concat(Array.new(ar - params.size, nil))
    end rescue nil

    # Return the data.

    return controller, "#{action}___super", query, params, format
  end

private

  def resolve_controller(controller)
    unless controller.ancestor?(Publishable)
      # The passed class is not a Controller.
      if controller.const_defined? :Controller
        # xxx::Controller class exists, use this as controller
        model = controller
        controller = controller::Controller
        controller.ann(:self, :model => model)
      end
    end

    # gmosx: test after attempting to resolve a 'default'
    # controller.
    raise ArgumentError.new("Invalid controller, cannot mount a Module") unless controller.is_a? Class

    unless controller.ancestor?(Publishable)
      # Make the given class a Controller.
      controller.send(:is, Publishable)
    end

    return controller
  end

end

end

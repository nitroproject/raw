require "raw/dispatcher"

module Raw

class Dispatcher

  # A Helper class used for CherryPy-style publishing. This is 
  # the prefered way to mount (publish) controllers to 
  # paths as it automatically defines a controller hierarchy.
  
  class Mounter # :nodoc: all
  
    def initialize(dispatcher, parent)
      @dispatcher, @parent = dispatcher, parent
    end
    
    def method_missing(sym, *args)
      name = sym.to_s

      if name =~ /=$/
        name = name.chop
        if controller = args.first
          # Store the hierarchical parent of this controller.
          # Useful for sitemaps etc.
          controller.ann(:self, :parent => @parent)
          @dispatcher[path(name)] = controller
        end
      else
        if controller = @dispatcher[path(name)]
          Mounter.new(@dispatcher, controller)
        end
      end
    end
    
    def path(name)
      "#{@parent.mount_path}/#{name}"
    end
  
  end

  # An alternative mounting mechanism (CherryPy like). Please
  # note tha following Nitro's standard practice 
  # dispatcher.root mounts to "" and not "/".
  #
  # Example:
  #
  #   dispatcher.root = RootController
  #   dispatcher.root.users = User::Controller
  #   dispatcher.root.users.comments = User::Comment::Controller
  # 
  # results to:
  #
  #   map = {
  #     "" => RootController
  #     "/users" => User::Controller
  #     "/users/comments" => User::Comment::Controller
  #   }

  def root=(controller)
    self[""] = resolve_controller(controller)
  end
  
  def root
    if controller = self[""]
      Mounter.new(self, controller)
    end
  end

end

end

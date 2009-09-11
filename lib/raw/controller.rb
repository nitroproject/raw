require "raw/controller/publishable"
require "raw/controller/render"

module Raw

# The Controller part in the MVC paradigm. Unlike the standard
# paradigm though a Raw Controller encapsulates the View part.
#
# The controller's published methods are called actions. The
# controller class contains the Publishable mixin and additional
# helper mixins.

class Controller

  is Publishable

  class << self

    # This callback is called after the Controller is mounted.

    def mounted(path)
    end

    # Returns the current controller from the context thread local
    # variable.

    def current
      Thread.current[:CURRENT_CONTROLLER]
    end

    #--
    # Replaces the current controller (helper for render).
    # This is an internal method.
    #++

    def replace_current(controller) # :nodoc:
      old = Thread.current[:CURRENT_CONTROLLER]
      Thread.current[:CURRENT_CONTROLLER] = controller
      return old
    end

  end # self

end

end

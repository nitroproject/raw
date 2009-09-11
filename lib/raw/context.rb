require "facets/kernel/assign_with"
require "facets/module/is"

require "raw/cgi"
require "raw/context/request"
require "raw/context/response"
require "raw/context/global"
require "raw/context/session"

require "raw/util/attr"

module Raw
  
# Encapsulates an HTTP processing cycle context. Integrates the 
# HTTP Request and the HTTP Response with Session, Global and
# Local variable stores.
#
# The Context object can be accessed by the context, request or 
# response aliases. You can use the alias that makes sense 
# every time. This means inside an action request, response and
# context all point to the same object.

class Context
  include Request
  include Response
 
  # The application of this context. Contains configuration
  # parameters.
  
  attr_accessor :application

  # The session contains variables that stay alive 
  # for the full user session. Session variables
  # should be generally avoided. This variable
  # becomes populated ONLY if needed.

  attr_reader :session

  # A hash to store some extra parameters for this request.
  
  attr_accessor :model

  # The rendering level. An action may include sub-actions,
  # each time the action is called, the level is increased,
  # when the action returns the level decreases. The first
  # action, called top level action has a level of 1.
  
  attr_accessor :level

  # The resource representation format for this request.
  
  attr_accessor :format

  # The output buffer accumulates the generated output.
  
  attr_accessor :output_buffer

  #--
  # FIXME: Don't allocate these hashes if not used!
  #++
  
  def initialize(application)
    @level = 0
    @application = application
    @post_params = {}
    @get_params = {}
    @response_headers = {}
    @output_buffer = ""
    @status = Http::STATUS_OK
    @model = {}

    # Store this instance in a thread local variable for easy
    # access.
    
    Thread.current[:CURRENT_CONTEXT] = self
  end

  # Don't sync session. This method may be needed in low level 
  # hacks with the session code. For example if you updade an
  # entity (managed) object that is cached in the session, you
  # may dissable the syncing to avoid resetting the old value
  # after the sync.
  
  def no_sync!
    @no_sync = true
  end
  
  # Close the context, should be called at the end of the HTTP 
  # request handling code.

  def close
    unless @no_sync
      @application.sessions.put(@session, self) if @session
    end
  end
  alias_method :finish, :close

  # Access the dispactcher
  
  def dispatcher
    @application.dispatcher
  end

  # Lazy lookup of the session to avoid costly cookie
  # lookup when not needed.

  def session
    @session ||= @application.sessions.get(self)
  end

  # Access global variables. In a distributed server scenario,
  # these variables can reside outside of the process.
  
  def global
    return Global
  end

  # Automagically populate an object from request parameters.
  # This is a truly dangerous method.
  #
  # === Options
  #
  # * name
  # * force_boolean
  #
  # === Example
  #
  # request.fill(User.new)
  #
  # This method is deprecated, Prefer to use the following form:
  #
  # User.new.assign_with(request)
  
  def fill(obj, options = {})
    AttributeUtils.populate_object(obj, params, options)
  end
  alias_method :populate, :fill
  alias_method :assign, :fill  
  
  # Is the current action the top level action? The level
  # of the top action is 1.
  
  def is_top_level?
    @level == 1
  end
  alias_method :top?, :is_top_level?
  alias_method :is_top?, :is_top_level?
  alias_method :top_level?, :is_top_level?

  # Returns the context for the current thread.
  
  def self.current
    Thread.current[:CURRENT_CONTEXT]
  end
    
end

end

module Raw

# The base class for all Nitro emmited errors and exceptions. 

class RawError < StandardError
end

# 4XX class errors (Client errors). Typically rendered when 
# a valid action cannot be found for a path.

class ActionError < RawError
end

# 5XX class errors.

class ServerError < RawError
end

#--
# Raise or Throw this exception to stop the current action.
# Typically called to skip the template. This is considerered
# a low level tactic. Prefer to use the exit method.
#++

class ActionExit < Exception # :nodoc: all
end 
  
#--
# Raise or Throw this exception to stop rendering altogether.
# Typically called by redirects.
#++

class RenderExit < Exception # :nodoc: all
end

end

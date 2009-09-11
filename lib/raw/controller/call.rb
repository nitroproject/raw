module Raw

#--
# Seaside style call/answer methods.
#++
  
module Render

private

  # Call redirects to the given URI but push the original
  # URI in a callstack, so that the target can return by 
  # executing answer. If the request is a POST request it
  # only does a simple redirect.
  #
  #--
  # FIXME: dont use yet, you have to encode the branch to 
  # make this safe for use.
  #++
  
  def call(*args)
    unless request.post?
      (session[:CALL_STACK] ||= []).push(request.uri)
    end
    redirect(*args)
  end

  # Returns from a call by poping the callstack.
  # Use force = false to make this mechanism more flexible.
  #--
  # FIXME: don't use yet.
  #++
    
  def answer(force = false, status = 303)
    if stack = session[:CALL_STACK] and not stack.empty?
      redirect(stack.pop, :status => status)
    else
      if force
        raise "Cannot answer, call stack is empty"
      else
        redirect_to_home
      end
    end
  end

end

end

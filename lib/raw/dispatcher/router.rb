require "cgi"

module Raw

# Routing (path rewriting) functionality. Due to the power of 
# Nitro's intelligent dispatching mechanism, routing is almost 
# never used! It is only needed for really special urls.

module RouterMixin

  # The routing rules.

  attr_accessor :rules
  
  # Add a routing rule
  #
  # Examples:
  #   r.add_rule(:match => %r{^~(.*)}, :controller => User::Controller, :action => view, :params => [:name])
  
  def add_rule(rule)
    @rules ||= []
    @rules << rule
  end
  alias_method :<<, :add_rule
  alias_method :add_route, :add_rule
        
  # Generate the transformer string for the match gsub. 
  
  def rule_transformer(rule)
    transformer = "#{rule[:controller].mount_path}/#{rule[:action]}"
    
    if params = rule[:params]
      params.size.times do |i|
        transformer << "/\\#{i+1}" 
      end
    end
        
    return transformer
  end

  # Convert routes defined with annotations to normal routes.
  # Typically called after a new Controller is mounted.
  #
  # Example of routing through annotations:
  #   def view_user
  #     "params:  #{request[:id]} and #{request[:mode]}"
  #   end
  #   ann :view_user, :match => /user_(\d*)_(*?)\.html/, :params => [:id, :mode] 

  def add_rules_from_annotations(controller)
    for m in controller.action_methods
      m = m.to_sym
      if match = controller.ann(m, :match)
        add_rule(:match => match, :controller => controller, :action => m, :params => controller.ann(m, :params))
      end
    end
  end

  # Try to decode the given path by applying routing rules. If
  # routing is possible return the transformed path, else return
  # the input path.
  
  def decode_route(path)
    # Front end server (for example Apache) some times escape 
    # the uri. REMOVE THIS: unescape in the adapter!!
    
    path = CGI.unescape(path)

    for rule in @rules
      unless transformer = rule[:transformer]
        transformer = rule[:transformer] = rule_transformer(rule)
      end

      if path.gsub!(rule[:match], transformer)
        debug "Rewriting '#{path}'." if $DBG
        break;
      end
    end
    
    return path
  end
  alias_method :route, :decode_route   

  # Encodes a [controller, action, params] tupple into a path.
  # Returns false if no encoding is possible.
  
  def encode_route(controller, action, *params)
    if rule = @rules.find { |r| (r[:controller] == controller) and (r[:action] == action) }
      path = rule[:match].source

      (params.size / 2).times do |i|
        val = params[i + i + 1]
        path.sub!(/\(.*?\)/, val.to_s)
      end       
      
      return path
    end
    
    return false
  end
          
end

# An abstract router.

class Router
  include RouterMixin
end

end

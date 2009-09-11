require "raw/dispatcher/format"

module Raw
  
#--
# Base class for Atom, RSS, XOXO, etc... formats
#++

class ServiceFormat < Format # :nodoc: all

  def after_action(controller, context)
    if controller.out.blank?
      title = 
        controller.class.ann(controller.instance_variable_get("@action"), :title) || 
        controller.instance_variable_get("@title")
      if model = controller.class.ann(:self, :model)
        resource = model.to_s.demodulize.underscore        
        if collection = controller.instance_variable_get("@models") || controller.instance_variable_get("@#{resource.plural}")
          controller.send(:print, serialize(collection, :title => title))
        elsif resource = controller.instance_variable_get("@model") || controller.instance_variable_get("@#{resource}") 
          controller.send(:print, serialize(resource, :title => title))
        end
      else
        warn "Generating #{@name} failed : #{controller.class} has no associated model"
      end
    end
  end
  
  # Override in subclasses.
  
  def serialize(resource_or_collection, options = {})
  end
  
end

end

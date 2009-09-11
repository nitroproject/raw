module Raw::Mixin

# View support for models. Provides hints for customized
# editing controls for this model.
#--
# THINK: Rename this to ModelView?
#++

class ModelUI

  def list_attributes
    []
  end
  
  def view(obj)
    "/"
  end
  
  class << self
  
  # Return a UI for the given model class. Return the default
  # if no UI class is defined.
  
  def for_class(klass)
    ui = nil
    
    begin
      ui = klass::UI.new
    rescue => ex
      ui = ModelUI.new
    end    
    
    return ui
  end
  alias_method :for, :for_class
  
  end
  
end

end

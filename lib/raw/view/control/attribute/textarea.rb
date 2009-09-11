require "raw/view/control/attribute"

module Raw

class TextareaControl < AttributeControl
  setting :style, :default => 'width: 500px; height: 100px', :doc => 'The default style'
  
  def render
    %{
    #{emit_label}
    <textarea id="#{control_id}" name="#{@attribute}"#{emit_style}#{emit_disabled}>#{@object.send(@attribute)}</textarea>
    }        
  end
end

end

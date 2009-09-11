require "raw/view/control/attribute"

module Raw

class TextControl < AttributeControl
  setting :style, :default => 'width: 250px', :doc => 'The default style'

  def render
    %{
    #{emit_label}
    <input type="text" id="#{control_id}" name="#{@attribute}" value="#{@object.send(@attribute)}"#{emit_style}#{emit_disabled} />
    }
  end
end

end

require "raw/view/control/attribute"

module Raw

# A Control used to edit boolean attributes.

class CheckboxControl < AttributeControl
  setting :style, :default => '', :doc => 'The default style'

  def render
    checked = @value == true ? ' checked="checked"' : ''
    %{
    <input type="checkbox" id="#{control_id}" name="#{@attribute}" #{emit_style}#{checked}#{emit_disabled} />&nbsp;#{emit_label}
    }
  end
  
  def emit_label
    return '' if @options[:no_label]
    title = @anno[:title] || @options[:label] || @attribute.to_s.humanize
    %{<label for="#{@attribute}" style="display: inline">#{title}</label>}
  end
  
end

end

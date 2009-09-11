require "raw/view/control/attribute"

module Raw

# Controls a Fixnum attribute.

class FixnumControl < AttributeControl
  setting :style, :default => 'width: 100px', :doc => 'The default style'

  def render
    style = @anno[:control_style] || self.class.style 
    %{
      #{emit_label}
      <input type="text" id="#{control_id}" name="#{@attribute}" value="#{value}"#{emit_style}#{emit_disabled} />
      <a href="#" onclick="el=document.getElementById('#{control_id}'); el.value=(parseInt(el.value) || 0)+#{step}; return false;">+</a>
      <a href="#" onclick="el=document.getElementById('#{control_id}'); el.value=(parseInt(el.value) || 0)-#{step}; return false;">-</a>
    }
  end
  
  def step
    1
  end
  
end

end

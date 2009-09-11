require "raw/view/control/attribute"

module Raw

# Controls a Fixnum attribute that can contain discreet values
# (options).
#
# === Example
#
# Pass a 'reverse' dictionary. Reverse to reuse the has for 
# easy rendering of labels. Dictionary to allow for ordered
# keys.
# 
# PRIORITY_VALUES = Dictionary[
#   0, :trivial,
#   1, :minor,
#   2, :major,
#   3, :blocker
# ]
#
# attr_accessor :priority, Fixnum, :control => :options, :options_data => PRIORITY_VALUES

class OptionsControl < AttributeControl
  setting :style, :default => 'width: 100px', :doc => 'The default style'

  def render
    style = @anno[:control_style] || self.class.style 
    data = @anno[:options_data]
    %{
      #{emit_label}
      <select id="#{control_id}" name="#{@attribute}">
        #{options :labels => data.values, :values => data.keys, :selected => value}
      </select>
    }
  end  
end

end

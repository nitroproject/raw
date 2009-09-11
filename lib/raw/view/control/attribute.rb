require "raw/view/control"

module Raw

# The base class for controls used to inspect object 
# attributes.
#--
# TODO: find a better name.
#++

class AttributeControl < Control

  # The attribute that this control renders.
  
  attr_accessor :attribute

  # The annotations used for rendering
  
  attr_accessor :anno
      
  # The value
  
  attr_accessor :value
  alias_method :values, :value
  
  # === Input
  #
  # * object = the object to inspect
  # * a = the attribute to inspect
  # * options = additional options
 
  def initialize(object, a, options)
    @object = object
    @attribute = a
    @anno = @object.class.ann(@attribute)
    @value = @object.send(@attribute)
    @options = options
  end
  
private

  # Used as id attribute in HTML markup.
  def control_id
    "#{@attribute}_ctl"
  end

  # Emit the label for this control.
  # The label is skipped if the control is created with the
  # option :no_label set to true.
  
  def emit_label
    return "" if @options[:no_label]
    title = @anno[:title] || @options[:label] || @attribute.to_s.humanize
    %{<label for="#{control_id}">#{title}</label>}
  end
    
  # Emit the css style for this control.
  # This mehtod takes into account the passed options (first) 
  # and then the attribute annotations.
  
  def emit_style
    unless style = (@options[:style] || @anno[:control_style])
      if self.class.respond_to? :style
        style = self.class.style
      else
        style = nil
      end
    end
    style ? %{ style="#{style}"} : ''
  end
  
  # Add support to your controls for being disabled
  # by including an emit_disabled on form items
  # or testing for is_disabled? on more complex controls.
  
  def emit_disabled
    is_disabled? ? %{ disabled="disabled"} : ''
  end
  
  #--
  # FIXME
  #++
  
  def is_disabled?
    return false if @options[:all]
    @options[:disable_controls] || @anno[:disable_control]
  end

end

end

require "raw/view/control/attribute"

module Raw

# The base class for controls used to inspect object 
# relations.
#--
# FIXME: this is a temp hack.
# TODO: Fix mismatches with attributes.
#++

class RelationControl < AttributeControl
  
  # === Input
  #
  # * object = the object to inspect
  # * symbol = the relation symbol
  # * anno = the relation annotations
  # * options = additional options
 
  def initialize object, rel, options
    @object = object
    @anno = rel
    @value = options[:value] || object.send(rel.name.to_sym)
    @options = options
  end

  def symbol
    @anno[:symbol]
  end
  
  def rel
    @anno
  end

private

  # Used as id attribute in HTML markup.
  def control_id
    "#{rel.name}_ctl"
  end


  # Emit the label for this control.
  # The label is skipped if the control is created with the
  # option :no_label set to true.
  #--
  # TODO: reuse attribute control version.
  #++
  
  def emit_label
    return '' if @options[:no_label]
    title = @anno[:title] || @options[:label] || @anno[:name].to_s.humanize
    %{<label for="#{control_id}">#{title}</label>}
  end

end

end

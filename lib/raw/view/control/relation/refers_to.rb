require "raw/view/control/relation"

module Raw

# RefersTo. Also used for BelongsTo.

class RefersToControl < RelationControl

  def render
    %{
    #{emit_label}
    <select id="#{control_id}" name="#{rel.name}"#{emit_disabled}>
    #{emit_options}
    </select>
    }
  end
  
  def emit_options
    objs = rel.target_class.all
    selected = selected.pk if selected = value
    %{
      <option value="">--</option>
      #{options(:labels => objs.map{|o| o.to_s}, :values => objs.map{|o| o.pk}, :selected => selected)}
    }
  end

end

end

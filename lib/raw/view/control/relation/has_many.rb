require "raw/view/control/relation"

module Raw

# HasMany, ManyToMany and JoinsMany

class HasManyControl < RelationControl
  
  #pre :do_this, :on => :populate_object
  
  def render
    str = "#{emit_label}"
    str << emit_container_start
    str << emit_js
    if selected_items.empty?
      str << emit_selector(:removable => false)
    else
      removable = selected_items.size != 1 ? true : false
      selected_items.each do |item|
        str << emit_selector(:selected => item.pk)
      end
    end
    str << emit_container_end
  end
  
  private 
  
  # these parts are seperated from render to make it easier
  # to extend and customise the HasManyControl
  
  def all_items
    return @all_items unless @all_items.nil?
    @all_items = rel.target_class.all
  end
  
  def selected_items
    if @object.saved?
      values
    else
      [] # gmosx, THINK: this is a hack fix!
    end
  end
  
  def emit_container_start
    %{<div class="many_to_many_container">}
  end
  
  def emit_container_end
    '</div>'
  end
  
  # :removable controls wether the minus button is active
  # :selected denotes the oid to flag as selected in the list
  
  def emit_selector(options={})
    removable = options.fetch(:removable, true)
    selected = options.fetch(:selected, nil)
    %{
    <div>
    <select class="has_many_ctl" name="#{rel.name}[]" id="#{control_id}" #{emit_style}#{emit_disabled}>
      <option value="">None</option>
      #{options(:labels => all_items.map{|o| o.to_s}, :values => all_items.map{|o| o.pk}, :selected => selected)}
    </select>
    <input type="button" class="#{rel.name}_remove_btn" value=" - " onclick="rm_#{rel.name}_rel(this);" #{'disabled="disabled"' unless removable} />
    <input type="button" class="#{rel.name}_add_btn" value=" + " onclick="add_#{rel.name}_rel(this);"#{emit_disabled} />
    </div>
    }
  end
  
  # Inline script: override this to change behavior
  
  def emit_js
    %{
    <script type="text/javascript">
      rm_#{rel.name}_rel = function(el){
        ctl=el.parentNode; 
        container=ctl.parentNode; 
        container.removeChild(ctl); 
        inputTags = container.getElementsByTagName('input');
        if(inputTags.length==2) 
          inputTags[0].disabled='disabled';
      }
      add_#{rel.name}_rel = function(el){
        ctl=el.parentNode; 
        container=ctl.parentNode; 
        node=ctl.cloneNode(true); 
        node.getElementsByTagName('input')[0].removeAttribute('disabled'); 
        if(container.lastChild==ctl) container.appendChild(node);
        else container.insertBefore(node, ctl.nextSibling);
        if(container.childNodes.length>1) container.getElementsByTagName('input')[0].disabled='';
      }
    </script>
    }
  end
end

end

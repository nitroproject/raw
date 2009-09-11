require "raw/view/form/controls"

module Raw

# A collection of useful helpers to help you convieniently 
# create html forms.
#
# You can also use the Forms alias.
# 
# Example usage:
#
#   <h1>Login</h1>
#   #{form :action => "/login"}
#   <label>Name</label><br />
#   #{text_field :name}
#   <br />
#   <input type="submit" name="Sumbit" />
#   #{end_form}
#
#   <h1>Login</h1>
#   <Form action="/login">
#   ...
#   </Form>
#--
# TODO: handle object parameters in helpers.
#++

module FormHelpers

  include FormControls

private

  DEFAULT_FORM_OPTIONS = {
    :method => :get
  }
  
  # The form start tag.
  
  def form(options = DEFAULT_FORM_OPTIONS)
    options = DEFAULT_FORM_OPTIONS.dup.update(options)

    html = "<form"
    
    for key, value in options
      case key
        when :action
        html << %{ action="#{R value}" }

        when :method     
        html << %{ method="#{value.to_s.upcase}"}
      
        else
        html << %{ #{key}="#{value}"}
      end
    end
       
    html << ">"
    
    return html
  end
  alias_method :start_form, :form
  
  # The form end tag.
  
  def end_form
    "</form>"
  end  

  # ------------------------------------------------------------
  
  # If flash[:ERRORS] is filled with errors structured as 
  # name/message pairs the method creates a div containing them, 
  # otherwise it returns an empty string. 
  #
  # So you can write code like:
  #   #{form_errors}
  #   <form>... </form>
  #
  # and redirect the user to the form in case of errors, thus 
  # allowing him to see what was wrong. 
  #--
  # WARNING: This helper deletes the errors from the flash.
  # THINK: think something more elegant.
  #++
  
  def form_errors
    if errors = flash.delete(:ERRORS) and (!errors.empty?)
      html = %{<div class="form_errors">\n<ul>\n}

      for err in errors
        if err.is_a? Array
          html << "<li><strong>#{err[0].to_s.humanize}</strong>: #{err[1]}</li>\n"
        else
          html << "<li>#{err}</li>\n"
        end
      end

      html << %{</ul>\n</div>\n}

      return html
    end
  end
  
  # ------------------------------------------------------------
  
  # Preserve a parameter in the request. Attach as a hidden 
  # element to the form.
  #
  # Example:
  #
  #   #{preserve_param :my_param}
  
  def preserve_param(*params)
    html = ""

    for par in params
      html << %{<input type="hidden" name="#{par}" value="#{request[par.to_s]}" />}
    end
    
    return html
  end
  alias_method :preserve_params, :preserve_param

  # Render a hidden field.
  
  def hidden_field(name, value)
    %{<input type="hidden" name="#{name}" value="#{value}"}
  end  

  # ------------------------------------------------------------

  # Render a text field.
  #
  # Example:
  #   #{text_field :title, :label => "The title of this content"}
  
  def text_field(name, options = {})
    html = "<p>"
    
    fid = options[:id] || name
    
    if label = options[:label]
      html << %{<label>#{label}</label>}
    end

    if value = options[:value]
      value = %{ value="#{value}"}
    else
      value = ""
    end

    if style = options[:style]
      style = %{ style="#{style}"}
    else
      style = ""
    end

    html << %{<input id="#{fid}" type="text" name="#{name}"#{value}#{style} />}

    if options[:required]
      html << %{&nbsp;<img src="/m/required.png" />}
    end

    html << "</p>"
        
    return html
  end

  # Render a text area.
  
  def text_area(name, options = {})
    html = "<p>"
    
    fid = options[:id] || name
    
    if label = options[:label]
      html << %{<label>#{label}</label>}
    end

    html << %{  
      <textarea id="#{fid}" name="#{name}">#{options[:value]}</textarea></p>
    }
    
    return html  
  end
  
  # Render a password text field.
  
  def password_field(name, options = {})
    html = "<p>"

    fid = options[:id] || name
        
    if label = options[:label]
      html << %{<label>#{label}</label>}
    end

    if value = options[:value]
      value = %{ value="#{value}"}
    else
      value = ""
    end

    html << %{<input id="#{fid}" type="password" name="#{name}"#{value} />}
    
    if options[:required]
      html << %{&nbsp;<img src="/m/required.png" />}
    end

    html << "</p>"
        
    return html
  end  
  
  # Render a select field.
  # Adds an undefined option with the special "--" marker.
  
  def select_field(name, options = {})
    html = "<p>"
    html << get_label(options)

    fid = options[:id] || name
    data = options[:select_options]
            
    html << %{
    <select id="#{fid}" name="#{name}">
      <option value="--">---</option>
      #{select_options :labels => data.values, :values => data.keys, :selected => options[:selected]}
    </select></p>
    }
  end
  
  # Render select options. The parameter is a hash of options.
  #
  # [+labels+]
  #   The option labels.
  #
  # [+values+]
  #    The corresponding values.
  #
  # [+labels_values+]
  #    Use when labels == values.
  #
  # [+selected+]
  #    The value of the selected option.
  #
  # Examples:
  #
  #   labels = ['Male', 'Female']
  #   select_options(:labels => labels, :selected => 1) 
  #--
  # WARNING: old code.
  #++
  
  def select_options(options = {})
    if labels = options[:labels] || options[:labels_values]
      str = ""
      
      values = options[:values] || options[:labels_values] || (0...labels.size).to_a
      
      selected = options[:selected]
      selected = selected.to_s if selected
      
      labels.each_with_index do |label, idx|
        value = values[idx]
        if options[:style]
          style = if options[:style].is_a?(Array) 
            options[:style][idx]
          else
            options[:style]
          end
          style = %{ style="#{style}"}
        end
        if value.to_s == selected
          str << %|<option value="#{value}" selected="selected"#{style}>#{label}</option>|
        else
          str << %|<option value="#{value}"#{style}>#{label}</option>|
        end
      end
      
      return str
    else
      raise ArgumentError.new("No labels provided")
    end
  end
  
  # Render a submit button.
  
  def submit_button(text, options = {})
    %{<input type="submit" value="#{text}" />}
  end

  # ...
  
  def checkbox(name, options = {})
    html = "<p>"
    
    fid = options[:id] || name
    
    if options[:selected] == true
      selected = %{ checked="true"}
    else
      selected = ""
    end
    
    html << %{  
      <input id="#{fid}" type="checkbox" name="#{name}"#{selected} />&nbsp;#{options[:label]}</p>
    }    
  end

  # ------------------------------------------------------------

  # Render a single attribute of an object.
  
  def attribute_control(obj, a, anno, options = {})
    name = anno[:control] || anno[:class] 
    control = FormControls::CONTROL_MAP.fetch(name, :no_control)
    return send(control, obj, a, anno, options)     
  end

  # Render the attributes of an object, using controls.
  
  def attribute_controls(obj, options = {})
    html = ""
    klass = obj.class
    excluded = [options[:exclude]].flatten
    
    for a in klass.serializable_attributes
      anno = klass.ann(a)
      unless options[:all]
        next if a == klass.primary_key or anno[:control] == :none or anno[:relation] or excluded.include?(a)
      end
      html << attribute_control(obj, a, anno, options)    
    end
    
    return html
  end

  # Render a relation control.
  
  def relation_control(obj, rel, options = {})
    if rel.is_a? Symbol
      # If the relation name is passed, lookup the actual
      # relation.
      rel = obj.class.relation(rel)    
    end
    
    name = rel[:control] || rel.class
    control_class = FormControls::CONTROL_MAP.fetch(name, :no_control)
    return send(control, obj, rel, options)     
  end
  
  # Render the relations of an object, using controls.
  
  def relation_controls(obj, options = {})
    html = ""
    klass = obj.class
    
    for rel in klass.relations
      unless options[:all]
        # Ignore polymorphic_marker relations.
        #--
        # gmosx: should revisit the handling of polymorphic
        # relations, feels hacky.
        #++
        next if (rel[:control] == :none) or rel.polymorphic_marker? 
      end
      html << relation_control(obj, rel, options)
    end
    
    return html
  end

  # ...

  def get_label(options)
    if label = options[:label]
      return %{<label>#{label}</label>}
    else 
      return ""
    end
  end

end

end


























__END__

module Raw

module Forms

module Helper
  # Mappings of control names to controls.
  
  setting :control_map, :doc => 'Mappings of control names to controls', :default => {
    :fixnum => FixnumControl,
    :integer => FixnumControl,
    :float => FloatControl,
    :true_class => CheckboxControl,
    :boolean => CheckboxControl,
    :checkbox => CheckboxControl,
    :string => TextControl,
    :password => PasswordControl,
    :textarea => TextareaControl,
    :file => FileControl,
    :webfile => FileControl,
=begin
    :array => ArrayControl,
=end
    :options => OptionsControl,
    :refers_to => RefersToControl,
    :has_one => RefersToControl,
    :belongs_to => RefersToControl,
    :has_many => HasManyControl,
    :many_to_many => HasManyControl,
    :joins_many => HasManyControl
  }

 
  CONTROL_MAP = {
    String => :text_field,
    Fixnum => :text_field
  }
 
 
  class << self

    # Returns a control for the given objects attribute.
    
    def control_for(obj, a, anno, options)
      raise "Invalid attribute '#{a}' for object '#{obj}'" if anno.nil?
      name = anno[:control] || anno[:class].to_s.demodulize.underscore.to_sym
      control_class = self.control_map.fetch(name, NoneControl)
      return control_class.new(obj, a, options) 

      name = anno[:control] || anno[:class] 
      control = CONTROL_MAP.fetch(name, :no_control)
      return send(:control, obj, a, options)     
    end

    # Returns a control for the given objects relation.

    def control_for_relation(obj, rel, options)
      name = rel[:control] || rel.class.to_s.demodulize.underscore.to_sym
      control_class = control_map.fetch(name, NoneControl)
      return control_class.new(obj, rel, options) 
    end

    def attribute(a, obj, options = {})
      if anno = obj.class.ann(a)
        control = control_for(obj, a, anno, options)
        return element(a, anno, control.render)
      else
        raise "Undefined attribute '#{a}' for class '#{@obj.class}'."
      end
    end
    alias_method :attr, :attribute

    def relation(rel, obj, options = {})
      # If the relation name is passed, lookup the actual
      # relation.
      
      if rel.is_a? Symbol
        rel = obj.class.relation(rel)    
      end

      control = control_for_relation(@obj, rel, options)
      return element(rel[:symbol], rel, control.render)
    end
    alias_method :rel, :relation


    # Emit a form element. Override this method to customize the
    # rendering for your application needs.
    
    def element(a, anno, html)
      # TODO: give better form id!
      %{
        <p id="form_#{a}">
          #{html}
        </p>
      }        
    end

  end
  
end

end

end

require "raw/view/form/helper"
require "raw/view/form/controls"

module Raw

# Add this module to your controllers to gain access to the
# form helper.

module Forms

private

  include FormHelpers
=begin  
  # Return an instance of the form helper.
  
  def form
    @__form_helper__ ||= AbstractFormHelper.new
    return @__form_helper__
  end
=end
    
end

end 





__END__

# The Form helper.

module FormHelper

  def text_field(name, options)
    res = "<p>"
    
    fid = options[:id] || name
    
    if label = options[:label]
      res << %{<label>#{label}</label><br />}
    end

    res << %{  
      <input id="#{fid}" type="text" name="#{name}" /></p>
    }
    
    return res
  end


  # Returns a control for the given objects attribute.
  
  def control_for(obj, a, anno, options)
    name = anno[:control] || anno[:class] 
    control = CONTROL_MAP.fetch(name, :no_control)
    return send(:control, obj, a, options)     
  end

end




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
  
  def form_errors
    if errors = flash[:ERRORS] and (!errors.empty?)
      res = %{<div class="form_errors">\n<ul>\n}

      for err in errors
        if err.is_a? Array
          res << "<li><strong>#{err[0].to_s.humanize}</strong>: #{err[1]}</li>\n"
        else
          res << "<li>#{err}</li>\n"
        end
      end

      res << %{</ul>\n</div>\n}

      return res
    end
  end

  # ------------------------------------------------------------
  
  # Preserver a parameter in the request. Attach as a hidden 
  # element to the form.
  
  def preserve_param(*params)
    html = ""

    for par in params
      html << %{<input type="hidden" name="#{par}" value="#{request[par.to_s]}" />}
    end
    
    return html
  end
  alias_method :preserve_params, :preserve_param

  # ------------------------------------------------------------
  
  # Render a hidden field.
  
  def hidden_field(name, value)
    %{<input type="hidden" name="#{name}" value="#{value}"}
  end  
  
  # Render a text field.
  
  def text_field(name, options = {})
    res = "<p>"
    
    fid = options[:id] || name
    
    if label = options[:label]
      res << %{<label>#{label}</label><br />}
    end

    res << %{  
      <input id="#{fid}" type="text" name="#{name}" /></p>
    }
    
    return res
  end
  
  # Render a text area.
  
  def text_area(name, options = {})
    res = "<p>"
    
    fid = options[:id] || name
    
    if label = options[:label]
      res << %{<label>#{label}</label><br />}
    end

    res << %{  
      <textarea id="#{fid}" name="#{name}"> </textarea></p>
    }
    
    return res  
  end
  
  # Render a password text field.
  
  def password_field(name, options = {})
    res = "<p>"

    fid = options[:id] || name
        
    if label = options[:label]
      res << %{<label>#{label}</label><br />}
    end

    res << %{  
      <input id="#{fid}" type="password" name="#{name}" /></p>
    }
    
    return res
  end  

  # No control
  
  def no_control
  end
  
  # Render a submit button.
  
  def submit_button(text)
    %{<input type="submit" value="#{text}" />}
  end

  #--
  # gmosx: copied form older code, should refactor and cleanup.
  #++
  
  # Render the attributes of a model.
  
  def object_attributes(obj, options = {})
    html = ""
    klass = obj.class
    excluded = [options[:exclude]].flatten
    
    for a in klass.serializable_attributes
      prop = klass.ann(a)
      unless options[:all]
        next if a == klass.primary_key or prop[:control] == :none or prop[:relation] or excluded.include?(a)
      end
      html << Forms::Helper.attribute(a, obj, options)    
    end
    
    return html
  end
  alias_method :attribute_fields, :object_attributes

  # Render the relations of a model.
  
  def object_relations(obj, options = {})
    html = ""
    
    for rel in @obj.class.relations
      unless options[:all]
        # Ignore polymorphic_marker relations.
        #--
        # gmosx: should revisit the handling of polymorphic
        # relations, feels hacky.
        #++
        next if (rel[:control] == :none) or rel.polymorphic_marker? 
      end
      html << Forms::Helper.relation(rel, options)
    end
    
    return html
  end

end

end

__END__

todo:
  
<form method="POST">
  #{text_field :email, :label => "Your email address"}    
  #{submit_button "Verify email"}
</form>
  
  
#{form_errors}

<form action="#{R :save}" method="POST">
  #{hidden_field :object_class_name, class_to_name(@obj.class)}
  #{object_fields @obj}
  <br />
  #{object_relations @obj}
  <p>
  #{submit_button "Save"} or <a href="#{R :list, :name, class_to_name(@obj.class)}">Cancel</a>
  </p>
</form>


use a proxy:

#{form.hidden : }
#{form.attributes }
#{form.relations }
#{form.submit }
#{form.textinput }
#{form.textarea }


#{form.start :object => @tumble}
#{form.submit}
#{form.end}

module Raw

# Form controls handle the rendering of object attributes. 
# 
# Each control, also shows validation errors.


module FormControls

  #--
  # TODO: make this a setting.
  #++
  
  CONTROL_MAP = {
    String => :string_control,
    Fixnum => :string_control,
    Date => :date_control,
    Time => :time_control,
    
    TrueClass => :checkbox_control,
    FalseClass => :checkbox_control,
    :checkbox => :checkbox_control,

    :password => :password_control,
    :textarea => :text_area_control,
    :select => :select_control,

    :has_many => :has_many_control,
    
    :no_control => :no_control
  }
  
private

  # :section: Attribute controls.
  
  def string_control(obj, a, anno, options)
    options = options.dup
    options[:label] ||= (options[:title] || a.to_s.humanize)
    options[:value] = CGI.escapeHTML(obj.send(a))
    html = text_field(a, options)

    return FormControls.attach_validation_errors(obj, a, html)
  end

  def password_control(obj, a, anno, options)
    options = options.dup
    options[:label] ||= (options[:title] || a.to_s.humanize)
    options[:value] = obj.send(a)
    html = password_field(a, options)
    
    return FormControls.attach_validation_errors(obj, a, html)    
  end

  def text_area_control(obj, a, anno, options)
    options = options.dup
    options[:label] ||= (options[:title] || a.to_s.humanize)
    options[:value] = CGI.escapeHTML(obj.send(a))
    html = text_area(a, options)

    return FormControls.attach_validation_errors(obj, a, html)    
  end

  def select_control(obj, a, anno, options)
    options = options.dup
    options.update(anno)
    options[:label] = options[:title] || a.to_s.humanize
    options[:selected] = obj.send(a)
    html = select_field(a, options)    

    return FormControls.attach_validation_errors(obj, a, html)    
  end

  def text_editor(obj, a, anno, options)
    ""
  end

  def time_control(obj, a, anno, options)
    label = options[:title] || a.to_s.humanize
    %{
    <label>#{label}</label>
    <input type="text" class="calendar" name="#{a}" />
    }
  end
  
  def date_control(obj, a, anno, options)
    ""
  end

  def checkbox_control(obj, a, anno, options)
    label = options[:title] || a.to_s.humanize    
    checkbox(a, :label => label, :selected => (obj.send(a) == true))  
  end

  # :section: Relation controls.
  
  def has_many(obj, rel, options)
    "<p>Has many relation</p>"
  end

  def no_control(obj, a, anno, options)
    "<p>No control for this attribute</p>"
  end

  # :section: 
  # Some meta-helpers (helper's helpers). Implemented as class
  # methods toavoid polluting the controller namespace.
  
  class << self
  
  # Attach validation errors (if there are any) to the control
  # html string.
  
  def attach_validation_errors(obj, a, html)
    if obj.validation_errors 
      if msgs = obj.validation_errors[a]
        html = %{
        <div class="form_error">
          #{html}
          <ul>
            #{msgs.map { |m| "<li>#{m}</li>"}.join}
          </ul>
        </div>
        }
      end
    end
    
    return html
  end
  
  end

end

end

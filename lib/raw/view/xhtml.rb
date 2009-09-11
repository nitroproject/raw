module Raw

# A helper mixin for programmatically building XHTML 
# blocks. 

module XhtmlHelper

  # Creates the href of an Object.
  #--
  # gmosx: this duplicates R functionality, merge!
  #++
    
  def href_of(obj, base = nil)
    if obj.is_a?(Symbol) or obj.is_a?(String)
      href = obj.to_s
    elsif obj.respond_to? :to_href
      href = obj.to_href
    else
      href = "#{obj.class.name.pluralize.underscore}/#{obj.oid}"
    end
    
    if base
      base += '/'
    else
      base = "#{self.class.mount_path}/".squeeze
    end
    
    return "#{base}#{href}"
  end

  # Creates a link to an Object.
  
  def link_to(obj, base = nil)
    %|<a href="#{href_of(obj, base)}">#{obj}</a>|
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
  # === Examples
  #
  # labels = ['Male', 'Female']
  # o.select(:name => 'sex') { 
  #   o.options(:labels => labels, :selected => 1) 
  # }
  #
  # or
  #
  # #{options :labels => labels, :values => [..], :selected => 1}
  # #{build :options, :labels => labels, :values => [..], :selected => 1}
  
  def options(options = {})
    if labels = options[:labels] || options[:labels_values]
      str = ''
      
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
      raise ArgumentError.new('No labels provided')
    end
  end

  # Convert a collection of objects to options.
  
  def objects_to_options(objs, params = {})
    labels = []
    values = []
    for obj in objs
      labels << obj.to_s
      values << obj.pk
    end
    params[:labels] = labels
    params[:values] = values
    options(params)
  end

  # Render a hidden form input.
  
  def hidden(name, value)
#   opts = options.collect { |k, v| %[#{k}="#{v}"] }.join(' ')
    %[<input type="hidden" name="#{name}" value="#{value}" />]
  end
  
  # Render a submit input.
  
  def submit(label, options = nil)
    str = ''
    
    label = options.delete(:value) unless label 
    
    str << '<input type="submit"'
    str << %[ value="#{label}"] if label

    unless options.empty?
      opts = options.collect { |k, v| %[#{k}="#{v}"] }.join(' ')
      str << %[ #{opts} ]
    end
    
    str << ' />'

    return str
  end

  # Render a date select. Override to customize this.
  #
  # === Example
  #
  # #{date_select date, :name => 'brithday'}

  def date_select(date, options = {})
    raise 'No name provided to date_select' unless name = options[:name]
    date ||= Time.now
    %{
      <select id="#{name}.day" name="#{name}.day">
        #{options(:labels_values => (1..31).to_a, :selected => date.day)}        
      </select>&nbsp;
      <select id="#{name}.month" name="#{name}.month">
        #{options(:labels => Date::MONTHNAMES[1..12], :values => (1..12).to_a, :selected => (date.month))}
      </select>&nbsp;
      <select id="#{name}.year" name="#{name}.year">
        #{options(:labels_values => ((Time.now.year-10)..(Time.now.year+10)).to_a, :selected => date.year)}        
      </select>}
  end
    
  # Render a time select. Override to customize this.

  def time_select(time, options = {})
    raise 'No name provided to time_select' unless name = options[:name]
    time ||= Time.now
    %{
      <select id="#{name}.hour" name="#{name}.hour">
        #{options(:labels_values => (1..60).to_a, :selected => time.hour)}        
      </select>&nbsp;
      <select id="#{name}.min" name="#{name}.min">
        #{options(:labels_values => (1..60).to_a, :selected => time.min)}        
      </select>}
  end
    
  # Render a datetime select. Override to customize this.
  
  def datetime_select(time, options)
    date_select(time, options) + '&nbsp;at&nbsp;' + time_select(time, options)
  end

  
  # gmosx: keep the leading / to be IE friendly.

  def js_popup(options = {})
    o = {
      :width => 320,
      :height => 240,
      :title => 'Popup',
      :resizable => false,
      :scrollbars => false,
    }.merge(options)

    poptions = (o[:resizable] ? 'resizable=yes,' : 'resizable=no,')
    poptions << (o[:scrollbars] ? 'scrollbars=yes' : 'scrollbars=no')
    
    uri = o[:url] || o[:uri]
    
    %[javascript: var pwl = (screen.width - #{o[:width]}) / 2; var pwt = (screen.height - #{o[:height]}) / 2; window.open('#{uri}', '#{o[:title]}', 'width=#{o[:width]},height=#{o[:height]},top='+pwt+',left='+pwl+', #{poptions}'); return false;"]       
  end

  # === Example
  #
  # <a href="#" #{onclick_popup 'add-comment', :scrollbars => true}>Hello</a>
  
  def onclick_popup(options = {})
    %|onclick="#{js_popup(options)}"|
  end
  
  # Emit a link that spawns a popup window.
  #
  # === Example
  #
  # <a href="#" #{onclick :text => 'Hello', :uri => 'add-comment', :scrollbars => true}>Hello</a>
  
  def popup(options = {})
    %|<a href="#" #{onclick_popup(options)}>#{options[:text] || 'Popup'}</a>|
  end
  
end

end


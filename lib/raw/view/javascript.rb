require "facets/inflect"

module Raw

# Javascript code manager.
#--
# TODO: Add support for synthesizing compound Javascript files from
# multiple smaller files.
#++

module Javascript
  
  # The javascript files to auto include.
  
  setting :required_files, :default => [], :doc => "The javascript files to auto include"

  # The root directory where javascript files reside.
  
  setting :root_dir, :default => "public/js", :doc => "The root directory where javascript files reside"

  def self.require(path)
  end

end

# Javascript utilities.

module JavascriptUtils

private
  # Escape carrier returns and single and double quotes for JavaScript segments.
  
  def escape_javascript(js)
    (js || '').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end
  alias_method :escape, :escape_javascript

  # Converts a Ruby hash to a Javascript hash.
  
  def hash_to_js(options)
    '{' + options.map {|k, v| "#{k}:#{v}"}.join(', ') + '}'
  end
  
  # Converts the name of a javascript file to the actual 
  # filename. Override if you don't like the defaults.
  
  def name_to_jsfile(name)  
    "/js/#{name}.js"
  end  

  # Generate javascript confirm code for links.

  def confirm(text = 'Are you sure?')
    %|onclick="return confirm('#{text}')"|
  end

end

end

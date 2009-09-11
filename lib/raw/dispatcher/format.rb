module Raw

# A REST Resource Representation format.

class Format

  # The name of this format.
  
  attr_accessor :name
  
  # The resource content type. Typically the resource MIME type 
  # is used.
  
  attr_accessor :content_type
  alias_method :mime_type, :content_type

  # The default resource extension.
  
  attr_accessor :extension
  
  # The default template extension.
  
  attr_accessor :template_extension
  
  def to_s
    @name
  end

  # Apply filters to the template source. The original template
  # representation must be transformed to executable Ruby code
  # at the end.
  
  def filter_template(source)
    return source
  end

  # This callback is called before the action is executed with
  # this format.
  
  def before_action(controller, context)
  end

  # This callback is called after the action is executed with
  # this format.
    
  def after_action(controller, context)
  end

  # Insert a filter in the template filters pipeline.
  
  def insert_filter(filter, pos = 0)
    if filter.is_a? Class
      filter = filter.new
    end
    @template_filters.insert(pos, filter)
  end
  
  # Insert a filter at the head of the template filters 
  # pipeline.
  
  def insert_filter_at_head(filter)
    insert_filter(filter, 0)  
  end

  # Insert a filter at the tail of the template filters 
  # pipeline.
  
  def insert_filter_at_tail(filter)
    insert_filter(filter, @template_filters.size)  
  end
  
  # Insert a filter before another filter class.
  
  def insert_filter_before(filter, other)
    insert_filter(filter, @template_filters.map(&:class).index(other))
  end
  
  # Insert a filter after another filter class.
  
  def insert_filter_after(filter, other)
    insert_filter(filter, @template_filters.map(&:class).index(other) + 1)
  end
  
end

# A Format Manager. Provides useful methods for fast Format
# lookup.

class FormatManager
  # Formats indexed by name.

  attr_accessor :by_name

  # Formats indexed by mime type.

  attr_accessor :by_mime_type

  # Formats indexed by extension.
  
  attr_accessor :by_extension  
    
  def initialize(*formats)
    @by_name = {}
    @by_mime_type = {}
    @by_extension = {}
    
    for format in formats.flatten
      put(format)
    end
  end

  # Add a new format to the manager.
    
  def put(format)
    if format.is_a? Class
      format = format.new
    end
    
    @by_name[format.name] = format          
    @by_mime_type[format.mime_type] = format          
    @by_extension[format.extension] = format          
  end
  alias_method :<<, :put
  
  # Lookup a format by name.
  
  def [](name)
    @by_name[name]
  end
  
end

require "raw/dispatcher/format/html"
require "raw/dispatcher/format/css"
require "raw/dispatcher/format/atom"
require "raw/dispatcher/format/rss"
require "raw/dispatcher/format/json"
require "raw/dispatcher/format/xoxo"

STANDARD_FORMATS = FormatManager.new(
  HTMLFormat, CSSFormat, ATOMFormat, RSSFormat, JSONFormat, XOXOFormat
)

end

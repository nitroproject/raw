require "raw/dispatcher/format"
require "raw/compiler/filter/template"
require "raw/compiler/filter/squeeze"
require "raw/compiler/filter/markup"
require "raw/compiler/filter/morph"
require "raw/compiler/filter/static_include"
require "raw/compiler/filter/elements"
require "raw/compiler/filter/cleanup"

module Raw

# Handler for CSS files.
  
class CSSFormat < Format

  def initialize
    @name = "css"
    @content_type = "text/css"
    @extension = "css"
    @template_extension = "css"
    @template_filters = [
      StaticIncludeFilter.new, 
      TemplateFilter.new
    ]
  end

  def filter_template(source)
    return if source.blank?
    
    for filter in @template_filters
      source = filter.apply(source)
    end
    
    return source
  end

  def after_action(controller, context)
    # Force caching of the generated css file.
    controller.send(:cache_output) unless $DBG
  end
      
end

end

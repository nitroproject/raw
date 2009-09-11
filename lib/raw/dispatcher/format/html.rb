require "raw/dispatcher/format"
require "raw/compiler/filter/template"
require "raw/compiler/filter/squeeze"
require "raw/compiler/filter/markup"
require "raw/compiler/filter/morph"
require "raw/compiler/filter/static_include"
require "raw/compiler/filter/elements"
require "raw/compiler/filter/cleanup"
require "raw/compiler/filter/asset"

module Raw
  
class HTMLFormat < Format

  def initialize
    @name = "html"
    @content_type = "text/html"
    if $KCODE == "UTF8"
      @content_type << "; charset=utf-8"
    end
    @extension = "html"
    @template_extension = "html"
    @template_filters = [
      StaticIncludeFilter.new, 
      ElementsFilter.new,
      MorphFilter.new,
      CleanupFilter.new,
      MarkupFilter.new,
      AssetFilter.new,
#     SqueezeFilter.new,
      TemplateFilter.new
    ]
  end

  # TODO: implement with Aspects.
  
  def before_action(controller, context)
    controller.send(:init_flash)
  end

  # TODO: implement with Aspects.  

  def after_action(controller, context)
    controller.send(:clean_flash)
  end

  def filter_template(source)
    return if source.blank?
    
    for filter in @template_filters
      source = filter.apply(source)
    end
    
    return source
  end
    
end

end

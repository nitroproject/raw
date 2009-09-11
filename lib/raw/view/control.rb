require "raw/compiler/filter/elements/element"
require "raw/view/xhtml"

module Raw

# A specialized kind of element used for implementing UI 
# controls.
#--
# TODO: add support for the singleton pattern to avoid excessive
# memory usage.
#++

class Control < Element  
  # THINK: maybe include this in element too?
  include XhtmlHelper
end

end

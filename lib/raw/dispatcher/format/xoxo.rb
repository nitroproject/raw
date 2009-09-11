require "blow/xoxo"

require "raw/dispatcher/format/service"

module Raw
  
class XOXOFormat < ServiceFormat

  def initialize
    @name = "xoxo"
    @content_type = $DBG ? "text/xml" : "application/xoxo+xml"
    @extension = "xoxo"
    @template_extension = "xoxo"
  end

  def serialize(resource_or_collection, options = {})
    XOXO.dump(resource_or_collection)
  end

end

end

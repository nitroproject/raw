require "blow/json"

require "raw/dispatcher/format/service"

module Raw
  
#--
# THINK: use .js extension ? (for javascript highlighting?)
#++

class JSONFormat < ServiceFormat

  def initialize
    @name = "json"
    @content_type = "application/json"
    @extension = "json"
    @template_extension = "json"
  end

  def serialize(resource_or_collection, options = {})
    resource_or_collection.to_json
  end
  
end

end

require "raw/util/atom"
require "raw/dispatcher/format/service"

module Raw

class ATOMFormat < ServiceFormat

  def initialize
    @name = "atom"
    @content_type = $DBG ? "text/xml" : "application/atom+xml"
    @extension = "atom"
    @template_extension = "atom"
  end

  def serialize(resource_or_collection, options ={})
    context = Context.current
    options[:id] = context.full_uri
    options[:title] = context.model[:action_annotation][:title]
    ATOM.dump(resource_or_collection, options)
  end

end

end

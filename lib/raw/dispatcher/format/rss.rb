require "blow/xoxo"

require "raw/dispatcher/format/service"

module Raw

#--
# TODO: implement me!
#++

class RSSFormat < ServiceFormat

  def initialize
    @name = "rss"
    @content_type = "text/xml"
    @extension = "xml"
    @template_extension = "xml"
  end

  def serialize(resource_or_collection, options = {})
    context = Context.current
    options[:id] = context.full_uri
    options[:title] = context.model[:action_annotation][:title]
    # FIXME: implement me!
  end
  
end

end

module Raw

# Add some useful web related methods to a Model.
#
# * to_s
# * to_href
# * to_uri
# * to_link
#
# You can still define these methods in your class to override
# this default behaviour.
#--
# gmosx: we use :define_method and the instance_methods.include?
# check to handle the case where these methods are already defined
# by another Module.
# THINK: rethink to_s handling.
#++
 
module Enchant

  def self.included(base)

    # to_href (the relative uri)
    #
    # If the class defines a text_key use it to create more
    # readable (and SEO friendly) URIs. The closure grabs the
    # defined parameters.

    controller = base.ann(:self, :controller) || base::Controller
    prefix = "#{controller.mount_path}/view".squeeze("/")
    key = base.ann(:self, :text_key) || "oid" 

    base.send(:define_method, :to_href) do
      "#{prefix}/#{send(key)}"
    end unless base.instance_methods.include? "to_href"

    # to_uri (the full uri)
    
    base.send(:define_method, :to_uri) do
      "#{Context.current.host_uri}#{to_href}"
    end unless base.instance_methods.include? "to_uri"
    
    # to_link
    
    base.send(:define_method, :to_link) do
      %|<a href="#{to_href}">#{to_s}</a>|
    end unless base.instance_methods.include? "to_link"

  rescue => ex
    warn "Model enchant error: #{ex}"
    # drink it!
  end

  def to_s
    @title || @name 
  end
  
  # Helper method, enchants all Models.
  
  def self.enchant_all_models
    for m in Og.models
      m.send(:include, self)
    end
  end
    
end

end

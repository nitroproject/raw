module Raw

# Asset related transformations.
#--
# TODO: handle <link> tags.
#++
#
class AssetFilter

  # The host for assets. Add a %d wildward to enable "load ballancing"
  # See http://www.die.net/musings/page_load_time/ for more 
  # details.
  #
  # Examples:
  #   AssetFilter.host = "asset.mysite.com"
  #   AssetFilter.host = "asset%d.mysite.com"
  
  setting :host, :default => nil, :doc => "The host for assets"

  # Transform asset tags. 
  
  def apply(source)
    source = source.dup

    # Pick an asset host for this source. Returns nil if no host 
    # is set, the host if no wildcard is set, or the host 
    # interpolated with the numbers 0-3 if it contains %d. The 
    # number is the source hash mod 4.
   
    if host = AssetFilter.host
      source.gsub!(/src="(.*)"/) do |match|
        path = $1.dup
        if path !~ /^http/ and path !~ /#\{/
          %{src="#{AssetFilter.uri(path)}"}
        else
          match
        end
      end
    end

    return source
  end
  
  class << self
  
  # Pick an asset host for this source. Returns nil if no host 
  # is set, the host if no wildcard is set, or the host 
  # interpolated with the numbers 0-3 if it contains %d. The 
  # number is the source hash mod 4.

  def compute_asset_uri(source)
    if host = AssetFilter.host
      source = "/#{source}" unless source =~ /^\//
      "#{host % (source.hash % 4)}#{source}"
    else 
      source
    end
  end
  alias_method :uri, :compute_asset_uri
  
  end

end

end

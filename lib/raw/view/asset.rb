module Raw; module Mixin

# A collection of useful methods for asset file handling. Assets
# are css files, javascript files, etc.

module AssetHelper

private

  # This helper timestamps asset files (css, js etc). Typically
  # used in 'skin' files to precalculate the actual path.
  #--
  # TEMP version: just attaches the $build number.
  #++
  
  def timestamp_asset(path)
    return "#{path}?t=#$app_build"
  end
  
  # Generate a link to a css file.
  
  def link_css(path, media = "screen")
    path = "/#{path}" unless path =~ %r{^/}
    path = "#{path}.css" unless path =~ %r{\.css$}
    %{<link href="#{timestamp_asset(path)}" media="#{media}" rel="Stylesheet" type="text/css" />}
  end

  # Include an external javascript file or files. Can accept
  # multiple files in one go.
  #
  # Example:
  #   #{include_javascript "jquery", "cookie", "human_time"}
  
  def include_javascript(*path)
    if path.size > 1
      xml = "" 
      for pt in path
        xml << include_javascript(pt)
      end
      return xml
    else
      path = path.first
      path = "/js/#{path}" unless path =~ %r{^/js}
      path = "#{path}.js" unless path =~ %r{\.js$}
      return %{<script src="#{timestamp_asset(path)}" type="text/javascript" />}
    end
  end

end

end; end

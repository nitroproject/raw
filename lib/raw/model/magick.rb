require "RMagick"

module Raw::Mixin

# Magick transformation.
#--
# TODO: pass generalized RMagick command.
#++

module Thumbnails

  # Default thumbnail width.
  
  setting :width, :default => 128, :doc => 'Default thumbnail width'

  # Default thumbnail height.
  
  setting :height, :default => 128, :doc => 'Default thumbnail height'

  class << self

    def create_thumbnail(src, tname, geostring)
      ext = File.extname(src)
      dst = "#{File.join(File.dirname(src), File.basename(src, ext))}_#{tname}#{ext}"

      thumb = Magick::Image.read(File.join(Nitro::Server.public_root, src)).first
      thumb.change_geometry!(geostring) do |cols, rows, thumb|
        thumb.resize!(cols, rows)
      end
      thumb.write(File.join(Nitro::Server.public_root, dst))
      
      return dst
    end
    alias_method :generate_thumbnail, :create_thumbnail
  
  end

end

end

require "fileutils"

require "facets/inheritor"
require "facets/settings"

module Raw::Mixin

# A Web File.
#
# You can customize the path where the uploaded file will be 
# by defining a webfile_path class method *before* the property:
#
# class Icon
#   def self.webfile_path request, name
#     File.join(Uploads.public_dir, request.user.name, 'icon.png')
#   end      
#
#   attr_accessor :file, WebFile, :magick => { :small => '64x64', :medium => '96x96' }    
# end
#--
# TODO: webfile_path customization sucks, should be improved!
#++

class WebFile

  # The directory where uploaded files are stored. Typically 
  # this is a symlink to another directory outside of the 
  # webapp dir for easier updates.
  
  setting :upload_dir, :default => "uploads", :doc => "The directory where upload files are stored"
  
  # Override files by default?
  
  setting :override_files, :default => true, :doc => "Override files by default?"

  # Modify the base class when this class is included as a
  # property
  #--
  # TODO: find a better name.
  #++
  
  def self.included_as_property(base, args)
    if args.last.is_a?(Hash)
      options = args.pop
    else
      options = Hash.new
    end
    
    args.pop if args.last.is_a?(Class)
    
    if thumbnails = (options[:thumbnail] || options[:thumbnails] || options[:magick]) or self.name == 'WebImage'
      require "raw/model/thumbnails"
      base.send :include, Thumbnails
      thumbnails = { :small => :thumbnails } if thumbnails.is_a?(String) 
    end
    
    for name in args
      base.module_eval do
        # The 'web' path to the file (relative to the public
        # root directory. Uses the original property name
        # or the #{name}_path alias.
                 
        attr_accessor name.to_sym, String, :control => :file
        alias_method "#{name}_path".to_sym, name.to_sym
        
        # The file size.
        
        attr_accessor "#{name}_size".to_sym, Fixnum, :control => :none
        
        # The mime type.

        attr_accessor "#{name}_mime_type".to_sym, String , :control => :none
     
        # Assignment callbacks.        
        #--
        # gmosx, FIXME: this is a hack!! better implementation
        # is needed (generalized property assigners).
       
        inheritor(:assign_callbacks, [], :merge) unless @assign_callbacks        
      end

      if thumbnails
        for tname in thumbnails.keys
          base.module_eval do
            attr_accessor "#{name}_#{tname}_thumbnail".to_sym, String, :control => :none
          end        
        end
      end

      code = %{
        def #{name}_real_path
          File.join($nitro_current_application.public_dir, @#{name})
        end

        def #{name}_from_request(request)
          param = request['#{name}']
          return if param.nil? or param.original_filename.blank?
      }
      if base.respond_to? "#{name}_webfile_path"
        code << %{
          path = #{name}_webfile_path(param)
        }
      else
        code << %{
          path = File.join(WebFile.upload_dir, WebFile.sanitize(param.original_filename))
        }
      end
      
      code << %{ 
          @#{name} = path
          @#{name}_size = param.size
          
          real_path = #{name}_real_path
          raise "File exists" if !WebFile.override_files and File.exists?(real_path)
          FileUtils.mkdir_p(File.dirname(real_path))
          if param.path
            FileUtils.cp(param.path, real_path)
          else
            # gmosx FIXME: this is a hack!!
            param.rewind
            File.open(real_path, "wb") { |f| f << param.read }
          end
          FileUtils.chmod(0664, real_path)
      }

      if thumbnails
        for tname, geostring in thumbnails
          code << %{
            @#{name}_#{tname}_thumbnail = Thumbnails.generate_thumbnail(path, '#{tname}', '#{geostring}') 
          }
        end
      end
            
      code << %{          
        end
        
        def delete_#{name}
          FileUtils.rm(#{name}_real_path)
        end

        assign_callbacks! << proc do |obj, values, options| 
          obj.#{name}_from_request(values)
        end
      }
      
      base.module_eval(code)
    end
  end
  
  # Sanitize a filename. You can override this method to make 
  # this suit your needs.
  
  def self.sanitize(filename)
    ext = File.extname(filename)
    base = File.basename(filename, ext).gsub(/[\\\/\? !@$\(\)]/, '-')[0..64]
    return "#{base}.#{ext}"
  end
    
end

# An alias, implies thumbnailing.

WebImage = WebFile

end

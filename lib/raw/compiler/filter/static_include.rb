module Raw

# Performs static includes. Typically you should include this 
# compiler as the first stage of the compile pipeline.
# 
# This compiler is extremely helpful, typically you would want
# to use static includes in many many cases.
 
class StaticIncludeFilter

  # Statically include sub-template files.
  # The target file is included at compile time.
  # If the given path is relative, the template_root stack of
  # the controller is traversed. If an absolute path is provided,
  # templates are searched only in Template.root
  #
  # gmosx: must be xformed before the <?r pi.
  #
  # Example:    
  #   <?include href="root/myfile.sx" ?>
  
  def apply(text)
    resolve_include(text)    
  end

  def resolve_include_filename(href)
    found = false

    if href[0] == ?/
      # Absolute path, search only in the application template
      # root.
      href = href[1, 999999] # hack!!
      template_dir_stack = [ Template.root_dir ]
    else
      template_dir_stack = Controller.current.ann(:self, :template_dir_stack)
    end
      
    for dir in template_dir_stack
      if File.exist?(filename = "#{dir}/#{href}")
        found = true
        break
      end

      if File.exist?(filename = "#{dir}/#{href}.inc.html")
        found = true
        break
      end
    end
    
    raise "Cannot statically include '#{href}'" unless found

    c = Context.current.application.compiler
    c.templates = c.templates.push(filename).uniq       

    return filename
  end

  def resolve_include(text)
    return text.gsub(/<\?include href=["|'](.*?)["|'](.*)\?>/) do |match|
      filename = resolve_include_filename($1)

      itext = File.read(filename)
      itext.gsub!(/<\?xml.*\?>/, '')
=begin
      itext = %{
      <?r begin ?>
      #{itext}
      <?r 
      rescue Object => ex 
        error "------------------------ERROR--------------------"  
      end 
      ?>
      }
      
      puts "===========", itext
=end
      # Recursively resolve to handle sub-includes.
      
      resolve_include(itext)
    end
  end
  
end

end

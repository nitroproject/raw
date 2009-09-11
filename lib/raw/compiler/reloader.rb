module Raw

# Autoreload classes and templates. Mainly useful while 
# debugging. Should be turned off in production servers to 
# avoid the severe performance penalty.

class Reloader
    
  def initialize(application)
    @application = application
    @mtimes = Hash.new(Time.now)
  end  

  # Start the monitor thread. This thread monitors code and
  # template files.
  #--
  # gmosx: the thread accesses the reloader variables through the
  # closure.
  #++
    
  def start(interval)
    @interval = interval
    @thread = Thread.new do 
      begin
        loop do
          sleep(@interval)

          dirty = false          

          # Check code files.
          
          for feature in $LOADED_FEATURES
            for path in $LOAD_PATH
              file = File.join(path, feature)
              if File.exist?(file) and is_dirty?(file)
                begin
                  dirty = true
                  load(feature)
                rescue Exception => ex
                  error ex.inspect
                end
              end
            end
          end

          # Check template files.
          
          for template in @application.compiler.templates
            if is_dirty? template
              dirty = true
              break
            end
          end
          
          reload_controllers() if dirty
        end # loop
      rescue => ex
        error ex
      end
    end
  end

  #  Stop the monitor thread.
  
  def stop
    @thread.exit
  end
  
  # Is a file modified on disk?
  
  def is_dirty?(file)
    if (mtime = File.stat(file).mtime) > @mtimes[file]
      debug "File '#{file}' is modified" if $DBG
      @mtimes[file] = mtime
      return true
    else
      return false
    end
  end
  
  # When a template is modified, remove all generated methods
  # from the controllers.
  
  def reload_controllers
    controllers = @application.dispatcher.controllers.values
    
    for c in controllers
      for m in c.private_instance_methods.grep(/(___super$)|(___view$)/)
        c.send(:remove_method, m) rescue nil
      end
    end
  end

end

end

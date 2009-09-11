require "fileutils"

require "facets/settings"
require "facets/file/write"
require "facets/kernel/eigenclass"

module Raw

# Add output caching to the Render.

module Caching

  # Enable or disable view caching.
  
  setting :enabled, :default => true, :doc => "Enable view caching"

private

  # Consider if the current action should be cached. Actually
  # caches the action if needed.
  
  def consider_cache_output
    return unless (caching_enabled? and caching_allowed?)

    if self.class.ann(@action, :cache) # or self.class.ann(:self, :cache)
      cache_output
    end
  end

  # Cache the output (view) of the current action. No checks
  # are performed, the caching is forced.
  
  def cache_output
    path = File.join(@context.application.public_dir, @context.path)
    FileUtils.makedirs(File.dirname(path))
    debug "Caching '#{path}'" if $DBG
    File.write(path, @out) 
  rescue => ex
    error(ex.to_s)
  end

  # Explicitly expire the given cached file. If the filename has
  # no  extension attach .* to  expire the cached files for
  # all format representations.
  #--
  # TODO: use encode_uri
  #++
  
  def expire_output(*args)
    path = encode_uri(*args)
    
    if File.extname(path).blank?
      # Clear all cached representations.
      if path =~ %r{/$} or path == ""
        path << "index.*"     
      else
        path << ".*"
      end
    end
    
    path = File.join(Context.current.application.public_dir, path)
    
    debug "Expiring cache files '#{path}'" if $DBG
    FileUtils.rm_rf(Dir.glob(path))
  rescue => ex
    # drink it!
  end
  alias_method :delete_output, :expire_output

  # Enable or disable caching. Can be overriden per controller
  # for extra fine grained caching control.
  
  def caching_enabled?
    Caching.enabled
  end  

  # Is caching allowed for this action (page)? The default
  # implementation does not cache post request or request 
  # with query parameters. You can work arround the second
  # 'limitation' by cleverly using Nitro's implicit support
  # for 'nice' URIs.
  
  def caching_allowed?
    not (@context.post? or @context.uri =~ /\?/)
  end

  class << self
    
    # Cleanup all the generated cache files. Typically called
    # from the Nitro console.
    #--
    # FIXME: this is a hackish implementation. 
    #++
    
    def cleanup_output
      for c in $app.dispatcher.mounted_controllers
        for a in c.actions
          if c.ann(a.to_sym, :cache) == true
            a = "" if a == "index"
            path = "#{c.mount_path}/#{a}".squeeze("/").chomp("/")
            path = "/index" if path.blank?
            info "Expiring #{$app.public_dir}#{path}/"
            FileUtils.rm_rf("#{$app.public_dir}#{path}/")
            info "Expiring #{$app.public_dir}#{path}.*"
            FileUtils.rm_rf(Dir.glob("#{$app.public_dir}#{path}.*"))
          end
        end
      end

      return true
    end
    alias_method :cleanup, :cleanup_output
    alias_method :clear, :cleanup_output
    
  end # self
  
end

end

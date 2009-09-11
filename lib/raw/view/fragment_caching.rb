require "raw/view/buffer"

module Raw::Mixin

# Add Fragment Caching functionality to your controller.

module FragmentCaching

  include BufferHelper

private

  def cache_fragment(key, options = {})
    if fragment = get_fragment(key, options)
      print(fragment)
    else
      open_buffer
      yield
      fragment = close_buffer
      put_fragment(key, fragment, options)
      print(fragment)
    end
  end

  def get_fragment(key, options = {})
    path = "cache/fragment#{key}.html"
    
    if File.exist? path
      return false if ttl = options[:ttl] and ttl < (Time.now - File.mtime(path))
      return File.read(path)
    else
      return false
    end
  end
  
  def put_fragment(key, val, options = {})
    path = "cache/fragment#{key}.html"
    
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, val)
  end

end

end

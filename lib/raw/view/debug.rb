module Raw

# A collection of useful debuging methods.

module DebugHelper

private

  # Returns a <pre>-tag set with the +object+ dumped by YAML. 
  # Very readable way to inspect an object.
  #--
  # TODO: make safe html.
  #++
  
  def debug(object)
    begin
      Marshal::dump(object)
      "<pre class='debug_dump'>#{object.to_yaml.gsub("  ", "&nbsp; ")}</pre>"
    rescue TypeError => ex
      # Object couldn't be dumped, perhaps because of singleton 
      # methods, this is the fallback.
      "<code class='debug_dump'>#{object.inspect}</code>"
    end
  end

end

end

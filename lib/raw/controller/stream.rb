require "raw/render"

module Raw

module Render

  # Enable streaming mode for the current HTTP Response.
  # You can optionally provide an existing IO object for 
  # streaming.
  #--
  # This code is considered a hack fix. But it still is useful 
  # so for the moment it stays in the distribution.
  #++
  
  def stream(io = nil)
    if io
      # Reuse an existing IO if it exists.
      @context.output_buffer = io
    else  
      r, w = IO.pipe
      
      @context.output_buffer = r
      @out = w
      r.sync = true    
      w.class.send(:define_method, :empty?) { false }
  
      Thread.new do 
        begin
          yield
        ensure
          w.close
        end
      end
    end
  end
  
end

end

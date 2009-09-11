module Raw::Mixin

# The output buffering mixin. Provides php-style output
# buffering functionality.
#
# === Examples
#
# <?r buf = capture do ?>
# ...
# <?r end ?>
#--
# TODO: use better names but keep the ob_xxx php style methods
# as aliases.
#++

module BufferHelper

private

  # Output buffers stack, used for php-style nested output 
  # buffering.
  
  def out_buffers; @out_buffers; end
  
  # Start (push) a new output buffer.

  def open_buffer
    @out_buffers ||= []
    @out_buffers.push(@out)
    @out = ""
  end
  alias_method :ob_start, :open_buffer
  
  # End (pop) the current output buffer.
  
  def close_buffer
    buf = @out
    @out = @out_buffers.pop
    return buf
  end
  alias_method :ob_end, :close_buffer
  
  # End (pop) the current output buffer and write to the parent.
  
  def close_and_write_buffer
    nested_buffer = @out
    @out = @out_buffers.pop
    @out << nested_buffer
  end
  alias_method :ob_write_end, :close_and_write_buffer
  
  def capture
    open_buffer
    yield
    return close_buffer
  end
  
end

end

require "raw/compiler/filter/morph/standard"

module Raw

# attribute: selected_if, checked_if, selected_unless, checked_unless
#
# <option value="1" selected_if="@cond">opt1</option>
#
# becomes
#
# <?r if @cond ?>
#   <option value="1" selected="selected">opt1</option>
# <?r else ?>
#   <option value="1">opt1</option>
# <?r end ?>

class SelectedIfMorpher < StandardMorpher
  def self.key
    "selected_if"
  end
  
  def before_start(buffer)
    @attr, @cond = @key.split("_")
    @attributes.delete(@key)
    @attributes[@attr] = @attr
    buffer << "<?r #@cond #@value ?> "
  end
  
  def after_start(buffer)
    @start_index = buffer.length
  end
  
  def before_end(buffer)
    @attributes.delete(@attr)
    @end_index = buffer.length
    buffer << Morphing.emit_end(@name)
    buffer << "<?r else ?>"
    buffer << Morphing.emit_start(@name, @attributes)
    buffer << buffer[@start_index...@end_index]
  end
end

end

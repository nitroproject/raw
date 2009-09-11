require "raw/compiler/filter/morph/standard"

module Raw

# attribute: if, unless
#
# <div prop1="one" if="@mycond" prop2="two">@mycond is true</div>
#
# becomes
#
# <?r if @mycond ?>
#   <div prop1="one" prop2="two">@mycond is true</div>
# <?r end ?>

class IfMorpher < StandardMorpher
  def self.key
    "if"
  end
  
  def before_start(buffer)
    buffer << "<?r #@key #@value ?> "
    @attributes.delete(@key)
  end
end

end

require "raw/compiler/filter/morph/standard"

module Raw

# attribute: each, for
#
# <li each="item in array">my item is #{item}</li>
#
# becomes
#
# <?r for item in array ?>
#   <li>my item is #{item}</li>
# <?r end ?>

class EachMorpher < Morpher
  def self.key
    "each"
  end
  
  def before_start(buffer)
    if @value =~ / in /
      buffer << "<?r for #@value ?> "
      attributes.delete(@key)
    end
  end
  
  def after_end(buffer)
    if @value =~ / in /
      buffer << " <?r end ?>"
    end
  end
end

end

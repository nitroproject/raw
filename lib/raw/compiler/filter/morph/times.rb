require "raw/compiler/filter/morph/standard"

module Raw

# attribute: times
#
# <li times="3">...</li>
# 
# becomes
#
# <?r 3.times do ?>
#   <li>...</li>
# <?r end ?>

class TimesMorpher < StandardMorpher
  def self.key
    "times"
  end
  
  def before_start(buffer)
    # gmosx: leave the trailing space.
    buffer << "<?r #@value.times do ?> "
    @attributes.delete(@key)
  end
end

end

module Raw

# The base morpher class. Morphers are triggered
# by a special 'key' attribute in the xml stream and
# transform the owner element. Typically used along with the
# MorphFilter.

class Morpher
  # The name of the tag.
  
  attr_accessor :name
  
  # The tag attributes.
  
  attr_accessor :attributes
  
  # The key
  
  attr_accessor :key
  
  # The value of the key.
  
  attr_accessor :value
  
  
  def initialize(name, attributes)
    @key = self.class.key
    @name = name
    @attributes = attributes
    @value = @attributes[@key]
  end  
  
  def before_start(buffer)
  end
  
  def after_start(buffer)
  end
  
  def before_end(buffer)
  end
  
  def after_end(buffer)
  end
end

# A useful super class for Morphers.

class StandardMorpher < Morpher
  def after_end(buffer)
    # gmosx: leave the leading space.
    buffer << " <?r end ?>"
  end
end

end

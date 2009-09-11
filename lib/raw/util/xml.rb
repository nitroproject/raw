require "xmlsimple"
require "facets/kernel/to_data"
require "facets/kernel/assign_with"

#--
# author: George Moschovitis, www.gmosx.com
#++

class Hash

  class XML # :nodoc:
    class << self
    
    def to_xml(hash)
      xml = ""
      
      for key, val in hash
        xml << "<#{key}>"
        xml << (Hash === val ? to_xml(val) : val.to_s)
        xml << "</#{key}>"
      end
      
      return xml
    end

    def from_xml(hash, xml)
      xml_hash = XmlSimple.xml_in(xml, "keeproot" => true)
      hash.update(flatten(xml_hash))
    end
      
    def flatten(hash)
      for key, val in hash
        if Array === val && val.size == 1
          hash[key] = val.first
        elsif Hash === val
          hash[key] = flatten(val)
        end
      end
      
      return hash
    end
    
    end
  end
  
  # Convert this hash to a simple xml representation.
  def to_xml
    Hash::XML.to_xml(self)
  end

  # Convert an xml fragment to a hash.
  def from_xml(xml)
    Hash::XML.from_xml(self, xml)
  end
    
end

class Object

  # Serialize an object to a simple xml representation.
  def to_xml
    self.to_data.to_xml
  end
  
  # Convert an xml fragment to a hash.
  def from_xml(xml)
    self.assign_with(Hash.new.from_xml(xml))
  end
  alias_method :assign_from_xml, :from_xml
  
end


__END__

# Test


class User
  attr_accessor :name, :age, :password
end

a = {:user => {:name => "gmosx", :age => 32, :password => "lala"}}
xml = a.to_xml
puts xml
u = User.new.from_xml(xml)
p u 

p "--"

class Category
  attr_accessor :title, :articles
  
  def initialize
    @articles = []
  end
end

c = Category.new
c.title = "My category"
c.articles << "Hello world"
c.articles << "This is nice"
c.articles << "It works"
puts c.to_xml # ! does not work as expected.

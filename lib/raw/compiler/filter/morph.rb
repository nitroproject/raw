require "rexml/document"
require "rexml/streamlistener"

require "facets/string/blank"

module Raw

# A Filter that transforms an xml stream. Multiple 'key' 
# attributes are supported per element.

class MorphFilter

  # The default morphers collection.
  
  setting :morphers, :default => Dictionary.new, :doc => "The default morphers collection"

  #--
  # The listener used to parse the xml stream.
  # TODO: add support for morphing comments, text, etc.
  #++
    
  class Listener # :nodoc: all
    include REXML::StreamListener

    attr_accessor :buffer

    def initialize(filter)
      super()
      @filter = filter
      @buffer = ""
      @stack = []
    end

    def tag_start(name, attributes)    
      morphers = []
      
      for morpher_class in @filter.morphers
        if attributes.has_key? morpher_class.key
          morphers << morpher_class.new(name, attributes)
        end
      end
      
      morphers.each { |h| h.before_start(@buffer) }
      @buffer << emit_start(name, attributes)
      morphers.each { |h| h.after_start(@buffer) }

      @stack.push(morphers)      
    end

    def tag_end(name)    
      morphers = @stack.pop
      morphers.reverse.each { |h| h.before_end(@buffer) }
      @buffer << emit_end(name)
      morphers.reverse.each { |h| h.after_end(@buffer) }
    end

    def text(str)
      @buffer << str
    end
    
    def instruction(name, attributes)
      @buffer << "<?#{name}#{attributes}?>"
    end

    def cdata(content)
      @buffer << "<![CDATA[#{content}]]>"
    end

    def comment(c)
      unless Template.strip_xml_comments
        @buffer << "<!--#{c}-->"
      end
    end    

    def doctype(name, pub_sys, long_name, uri)   
      @buffer << "<!DOCTYPE #{name} #{pub_sys} #{long_name} #{uri}>\n"
    end  

    def emit_start(name, attributes)
      attrs = attributes.map{ |k, v| %|#{k}="#{v}"| }.join(' ')
      attrs.blank? ? "<#{name}>" : "<#{name} #{attrs}>"
    end
  
    def emit_end(name)
      "</#{name}>"
    end
  end # Listener

  # A collection of morphers registered with this filter.
  
  attr_accessor :morphers
  
  # Initialize the filter.
  
  def initialize(morphers = nil)
    unless @morphers = morphers
      require "raw/compiler/filter/morph/times"
      require "raw/compiler/filter/morph/each"
      require "raw/compiler/filter/morph/for"
      require "raw/compiler/filter/morph/if"
      require "raw/compiler/filter/morph/selected_if"
      
      @morphers = [ 
        TimesMorpher, 
        EachMorpher, 
        ForMorpher, 
        IfMorpher, 
        SelectedIfMorpher 
      ]
    end
  end

  # Apply the filter.
    
  def apply(source)
    listen = Listener.new(self)
    REXML::Document.parse_stream(source, listen)
    return listen.buffer
  end
  
end

end

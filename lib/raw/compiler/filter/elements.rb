require "rexml/document"
require "rexml/streamlistener"

require "facets/kernel/constant"

require "raw/compiler/filter/elements/element"

module Raw

# A filter that transforms user defined Elements. Elements
# are custom tags that are used as macros or to implement
# skins. 
# 
# Example:
#   <MainPage>
#     ... 
#   </MainPage>
#
# Alternative (more xml compliant) notation:
#   <x:main-page>
#     ...
#   </x:main-page>
#
# both evaluate the Element class:
#
# class MainPage
# end

class ElementsFilter

  class Listener # :nodoc: all
    include REXML::StreamListener

    PREFIX_RE = /^#{Element.prefix}:/
    CAPITALIZED_RE = /^[A-Z]/
        
    attr_accessor :buffer
    
    def initialize
      super()
      @buffer = ''
      @idcount = {}
      @stack = []
    end
    
    def tag_start(name, attributes)    
      if klass = is_element?(name)
        id = attributes.delete("id") || 
               klass.name.demodulize.underscore

        if @idcount[id] # Make sure an id is unique in the page
          @idcount[id] += 1
          id = "#{id}_#{@idcount[id]}"
        else
          @idcount[id] ||= 0
        end

        obj = klass.new(id)
         
        attributes.each do | k, v | 
          obj.instance_variable_set("@#{k}", v)
        end        
          
        @stack.push [obj, @buffer, @parent]
          
        @buffer = obj._text
        @parent.add_child(obj) if @parent
          
        @parent = obj
      else # This is a static element.
        attrs = []
        
        attributes.each do | k, v | 
          attrs << %|#{k}="#{v}"|
        end
        
        attrs = attrs.empty? ? nil : " #{attrs.join(' ')}"
        
        @buffer << "<#{name}#{attrs}>"
      end
    end

    def tag_end(name)    
      if is_element? name
        obj, @buffer, @parent = @stack.pop
        @buffer << obj.render.to_s
      else
        @buffer << "</#{name}>"
      end
    end

    # Check if a tag is an Element. If found, it also tries to 
    # auto-extend the klass. Returns the Element class if found.
    #
    # Tries many classes in the following order:
    #
    # * Controller::XXX
    # * {controller.ann(:self, :element_namespace)}::XXX
    # * Raw::Element::XXX
    
    def is_element?(name)
      controller = Controller.current
      
      return false unless name =~ PREFIX_RE or name =~ CAPITALIZED_RE

      name = name.gsub(PREFIX_RE, "").gsub(/-/, "_").camelize if name =~ PREFIX_RE

      # Try to use Controller::xxx
      # gmosx, THINK: this looks a bit dangerous to me!
=begin      
      begin
        # gmosx, FIXME: Class.by_name also returns top level
        # classes, how can we fix this?

        klass = constant("#{controller}::#{name}")
      rescue 
        # drink it!
      end
=end
      # Try to use the Controller's :element_namespace annotation

      if namespace = controller.ann(:self, :element_namespace)
        begin
          klass = constant("#{namespace}::#{name}")
        rescue
          # drink it!
        end
      end unless klass

      # Try to use Raw::Element::xxx then ::xxx
      
      begin
        klass = constant("Raw::Element::#{name}")
      rescue
        # drink it!
      end unless klass

      return false unless klass.kind_of? Class

      # Try to auto-extend.

      unless klass.ancestor? Element
        if Element.auto_extend
          klass.send(:include, ElementMixin)
        else
          return false
        end
      end
      
      return klass
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
  end # Listener

  # Apply the filter.
  
  def apply(source)
    listen = Listener.new
    REXML::Document.parse_stream(source, listen)
    return listen.buffer
  end

end

end

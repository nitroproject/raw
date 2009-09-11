require "raw/compiler/reloader"

module Raw

# The Compiler dynamically generates action methods for the
# Controllers.

class Compiler

  # A collection of the loaded template files.
  
  attr_accessor :templates

  # The reloader monitors and reloads code and template files.
  
  attr_accessor :reloader

  # Initialize the compiler.
  
  def initialize(application)
    @application = application
    @reloader = Reloader.new(application)
    @templates = []
  end

  # This method compiles missing Controller methods. Only handles
  # xxx___super and xxx___{format}___view methods.
  
  def compile(controller, meth)
    meth = meth.to_s

    if meth =~ %r{___super$}
      compile_super(controller, meth)
    elsif meth =~ %r{___view$}
      compile_view(controller, meth)
    else
      return false
    end
  end

  # Compile the action super-method for the given URI. This
  # super-method calls the action and view sub-methods. The
  # action sub-method is typically provided by the controller.
  #
  # In a sense, the super-method orchestrates the action and 
  # view sub-methods to handle the given URI.

  def compile_super(controller, meth)
    action = meth.gsub(%r{___super$}, "")

    debug "Compiling '#{controller}##{action}' super-method" if $DBG        

    if controller.action_or_template?(action, Context.current.format)
      
      # This is the actual control super method that calls
      # the action code and the template for this format.
      
      code = lambda do |params|
        @context.format.before_action(self, @context)

        @action = action.to_sym 
        
        # Keep the annotation easily accessible. 
        # THINK: is there a better way?
        @context.model[:action_annotation] = self.class.ann(@action)
        
        # Call the action sub-method.

        action_out = send(action, *(params || [])) if respond_to? action

        # gmosx: The following test is a nasty hack, avoids 
        # evaluating (a potentially 'overloaded' template) for 
        # the top level action to avoid some confusion. Run the 
        # hello example without this test to see what I mean. 
        # Anyone can think of a better solution?
        unless (@context.level == 0) and (!@out.empty?)                  
          # Call the view sub-method (render the template).
          
          send("#{action}___#{@context.format}___view")
        end

        # If the output buffer is empty and the action returned
        # a String, append it to the buffer. This allows code
        # like this:
        #
        #   def my_action
        #     %{
        #     <html>
        #       <body>
        #       #{Time.now}
        #       </body>
        #     </html>
        #     }
        #   end
        #
        # However, you should really use the print method
        # to make your code more readable.
        
#  gmosx: removed again, it fucks up formats.
#       
#        if action_out.is_a?(String) and @out.empty?
#          @out << action_out
#        end

        @context.format.after_action(self, @context)
        
        consider_cache_output()        
      end # lambda
      
      controller.send(:define_method, meth, code)
      controller.send(:private, meth)
      
      return true
    else
      return false
    end
  end
  
  # Compile the view sub-method for the given URI. 
  #--
  # The sub-method is always generated, if no template is found
  # it is just a nop method.
  #
  # TODO: cache the generated files (reuse the  cached files
  # to extract error regions)
  #++  
  
  def compile_view(controller, meth)
    md = meth.match(%r{(.*)___(.*)___view})
    action, format = md[1], md[2]

    format = @application.dispatcher.formats[format]

    debug "Compiling '#{action}' view sub-method [format: #{format}]" if $DBG        

    unless controller.instance_methods.include? meth
      # The view method is missing. The Compiler will try to 
      # use a template or generate an empty view method.
      
      template = nil
      
      if path = controller.template_path(action, format)
        # Keep a ref of this template for the reloader.
        
        @templates = @templates.push(path).uniq
        
        # Read the template source.
                
        template = File.read(path)

        # Apply the template filters.
        
        unless template.blank? 
          template = format.filter_template(template)
        end
      end

      controller.class_eval <<-EOCODE # , path, 0 
        def #{meth}
          #{template}
        end
      EOCODE
      
      controller.send(:private, meth)
    end
        
    return true
  end

end

end

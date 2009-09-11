require "og/aspects"

module Raw

  # This module adds flashing support to the Controllers. 
  
  module Flashing
  
    # A Flash is a special hash object that lives in the session. 
    # The values stored in the Flash are typically maintained 
    # for the duration of one request. After the request is over,
    # the Hash is cleared.
    # 
    # You may want to use the Flash to pass error messages or 
    # other short lived objects.
    #
    # Use capitalized keys to denote system variables. Reserve
    # lower case keys for user application variables.
        
    class Flash < Hash
    
      def initialize
        super
        @dirty = {}
      end
    
      def []=(key, val)
        super
        keep(key)
      end

      # Keep the specific key or the whole Flash.
            
      def keep(key = nil)
        set_dirty(key, false)
      end
      
      # Discard the specific key or the whole Flash.
      
      def discard(key = nil)
        set_dirty(key)
      end      
      
      def clean # :nodoc:
        @dirty ||= {}
        keys.each do |k|
          unless @dirty[k]
            set_dirty(k)
          else
            delete(k)
            @dirty.delete(k)
          end
        end
        
        # remove externaly updated keys.
        
        (@dirty.keys - keys).each { |k| @dirty.delete k } 
      end

      # :section: Helpers
      
      # Push a value in an array flash variable.
      #
      # Example:
      #
      #   flash.push :ERRORS, 'This is the first error'
      #   flash.push :ERRORS, 'This is the second error'
      #
      #   flash[:ERRORS] # => []
      
      def push(key, *values)
        val = self[key]
        val ||= []
   
        if values.size == 1
          val << values[0]
        else
          val.concat(values)
        end

        self[key] = val
      end
      
      # Pop a value from an array flash variable.
      
      def pop(key)
        if arr = self[key]
          if arr.is_a? Array
            return arr.pop
          else
            return arr
          end
        end
        return nil
      end

      # Another helper, concats a whole array to the given flash
      # key.
      
      def concat(key, arr)
        for val in arr.to_a
          push key, val
        end
      end      

      # Join helper
      
      def join(key, sep = ", ")
        value = self[key]
        
        if value.is_a? Array
          return value.join(sep)
        else
          return value
        end
      end
            
    private
      
      def set_dirty(key = nil, flag = true)
        @dirty = {}
        if key
          @dirty[key] = flag
        else
          keys.each { |k| @dirty[k] = flag }
        end      
      end
      
    end # Flash

=begin    
    # FIXME: This doesn't seem to work :(
    
    def self.included(base)
      base.before(:call => :init_flash)
      base.after(:call => :clean_flash)
    end
=end
    
  private

    def flash
      session[:FLASH] ||= Flash.new
    end
        
    # Some useful aspects.
      
    # Marks flash entries as used and expose the flash to the 
    # view.
    
    def init_flash
      flash.discard
    end

    # Deletes the flash entries that were not marked for 
    # keeping.
    
    def clean_flash
      flash.clean
    end

    # A helper for error passing through flash. Pushes the 
    # provided error to the flash[:ERRORS] array.
    
    def flash_error(err)
      unless (err.is_a? String) or (err.is_a? Array)
        if err.respond_to? :to_a
          flash.push :ERRORS, *(err.to_a)
        end
      else
        flash.push :ERRORS, err
      end
    end
    
    def flash_errors?
      !flash[:ERRORS].empty?
    end

  end  

end

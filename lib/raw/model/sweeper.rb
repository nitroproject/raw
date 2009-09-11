require "raw/controller/caching"
require "raw/util/encode_uri"

module Raw::Mixin

# This module adds cleanup functionality to managed 
# classes. Override and implement sweep_affected.
# Typically used to cleanup output caching files from
# the filesystem. But you can also use it to clean up
# temp objects in the database or other temp files.
#--
# FIXME: find a better name.
#++

module Sweeper
  extend Raw::Caching
  extend Raw::EncodeURI  
  
  #--
  # Inject the sweepers *after* the event to have a valid
  # oid.
  #++
    
  before :og_insert do 
    sweep_affected(:insert) unless $sweeper_dissabled
  end

  before :og_update do 
    sweep_affected(:update) unless $sweeper_dissabled
  end

  before :og_delete do 
    sweep_affected(:delete) unless $sweeper_dissabled
  end
  
private

  # If needed pass the calling action symbol to allow
  # for conditional expiration.
  # Action takes values from { :insert, :delete, :update }
  # or your own custom enumeration.
  #
  # Generally add lines like the following:
  #
  # expire_output("file_to_expire")
  # expire_output(Controller, :action)
  # expire_output(obj) # uses obj.to_href
    
  def sweep_affected(action = :all)
  end
  
  # Called from an action that modifies the model to expire 
  # affected (dependend) cached pages. Generally you don't 
  # override this method.
    
  def expire_affected_output(*args)
    Sweeper.send(:expire_output, *args)
  end
  alias_method :expire_output, :expire_affected_output

  # Expire affected cached fragments.
  
  def expire_affected_fragment(name, options = {})
    # TODO
  end
  alias_method :expire_fragment, :expire_affected_fragment
  
end

end

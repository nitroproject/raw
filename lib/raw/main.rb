# = Raw, Rapid Applications for the Web 
#
# Copyright (c) 2004-2007, George Moschovitis (http://www.gmosx.com)
#
# Raw (http://www.nitroproject.org) is copyrighted free software 
# created and maintained by George Moschovitis 
# (mailto:george.moschovitis@gmail.com) and released under the 
# standard BSD Licence. For details consult the file doc/LICENCE.

require "facets"
require "facets/annotations"

#require "facets/module/is"  # DON'T NEED THIS

module Raw
  # The version of Raw.

  Version = "0.50.0"
  
  # Library path.

  LibPath = File.dirname(__FILE__)
  
  # The Mixin namespace.
  
  module Mixin; end
  
  # Include the Mixin namespace.
  
  include Mixin
end

# Include Raw::Mixin in the TopLevel for extra convienience.

include Raw::Mixin unless $NITRO_DONT_INCLUDE_MIXINS

#--
# gmosx: leave them here.
#++

require "raw/autoload"
require "raw/errors"
require "raw/context"
require "raw/context/global"
require "raw/controller"
require "raw/dispatcher"

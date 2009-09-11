require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'
require 'ostruct'

require 'nitro/helper'

class Base
  include Nitro::Helpers
end

module MyHelper
  def hello_world
    return 5
  end
end

module AnotherHelper
  def bye_world
    return 0
  end
end

module Funny
  def funny_world
    return 1
  end
end

class MyBase < Base
  helper :my
  helper AnotherHelper
end

class TC_Helper < Test::Unit::TestCase # :nodoc: all
  def test_all
    assert !MyBase.public_instance_methods.include?('hello_world')
    assert MyBase.private_instance_methods.include?('hello_world')
    assert !MyBase.public_instance_methods.include?('bye_world')
    assert MyBase.private_instance_methods.include?('bye_world')

    # test a bug.
    MyBase.helper(Funny)
    assert !MyBase.public_instance_methods.include?('funny_world')
    assert MyBase.private_instance_methods.include?('funny_world')    
  end  
end

require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'
require 'ostruct'

require 'nitro'
require 'nitro/controller'
require 'nitro/flash'

class TC_Flash < Test::Unit::TestCase # :nodoc: all
  include Nitro

  class MyController < Controller
    attr_accessor :flag
    
    def action1
      flash[:msg] = 'Hello world!'
    end
    
    def action2
      @flag = flash[:msg]
    end
  end

  def setup
    @conf = OpenStruct.new
  end

  def teardown
    @conf = nil
  end
  
  def test_all
    ctx = Context.new(@conf)
    ctx.headers = {}
    ctx.params = {}
    ctx.instance_eval '@session = {}'
    c = MyController.new(ctx)  
    c.action1
    c.action2
    assert_equal 'Hello world!', c.flag
    c.action2
    assert_equal 'Hello world!', c.flag
  end  
  
  def test_push
    f = Flashing::Flash.new
    f.push :errors, 'Error 1'
    f.push :errors, 'Error 2'
    
    assert_equal 2, f[:errors].size
    
    f.push :errors, 'Error 3'
    
    assert_equal 3, f[:errors].size
    
    assert_equal 'Error 3', f[:errors].pop
  end
end

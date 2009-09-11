require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'
require 'ostruct'

require 'nitro/dispatcher/router'

class IdController; end
class AdminController; end

class AbstractRouter
  include Nitro::Router
  
  def initialize
    init_routes()
  end
end

class TC_Router < Test::Unit::TestCase # :nodoc: all
  include Nitro

  def setup
    @r = AbstractRouter.new

    @r.add_rule(:match => %r{rewritten/url/(.*)}, :controller => IdController, :action => :register, :param => :name)
    @r.add_rule(:match => %r{another/zelo/(.*)/(.*)}, :controller => AdminController, :action => :kick, :params => [:name, :age])
    @r.add_rule(:match => %r{cool/(.*)_(.*).html}, :controller => AdminController, :action => :long, :params => [:name, :age])
  end
  
  def teardown
    @r = nil
  end
    
  def test_decode
    c, a, params = @r.decode_route('rewritten/url/gmosx')
    assert_equal IdController, c   
    assert_equal :register, a 
    assert_equal 'gmosx', params['name']  
    
    c, a, params = @r.decode_route('another/zelo/gmosx/32')
    assert_equal AdminController, c   
    assert_equal :kick, a 
    assert_equal 'gmosx', params['name']      
    assert_equal '32', params['age']

    c, a, params = @r.decode_route('cool/gmosx_32.html')
    assert_equal AdminController, c   
    assert_equal :long, a 
    assert_equal 'gmosx', params['name']      
    assert_equal '32', params['age']
    
    assert_equal false, @r.decode_route('this/doesnt/decode')      
  end

  def test_encode
    assert_equal 'rewritten/url/gmosx', @r.encode_route(IdController, :register, :name, 'gmosx')
    assert_equal 'cool/gmosx_32.html', @r.encode_route(AdminController, :long, :name, 'gmosx', :age, 32)
    assert_equal false, @r.encode_route(AdminController, :invalid, :gender, 'male')
  end

end

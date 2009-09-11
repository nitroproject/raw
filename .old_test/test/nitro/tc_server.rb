require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'

require 'nitro/server'

class TC_Server < Test::Unit::TestCase # :nodoc: all
  include Nitro
  
  class RootController
  end

  class UsersController
  end
  
  class TestController
  end
  
  class DeepController
  end
  
  def test_all
    srv = Server.new('test')
    
    srv.root = RootController
    srv.root.users = UsersController
    srv.root.test = TestController
    srv.root.really.really.deep = DeepController
    
    assert_equal RootController, srv.map['/']
    assert_equal UsersController, srv.map['/users']
    assert_equal TestController, srv.map['/test']
    assert_equal DeepController, srv.map['/really/really/deep']
  end
end

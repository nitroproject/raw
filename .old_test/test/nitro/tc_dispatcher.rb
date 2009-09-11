require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'

require 'nitro/dispatcher'

class TC_Dispatcher < Test::Unit::TestCase # :nodoc: all
  include Nitro

  class Link
  end

  class Link::Comment
  end

  class Link::Controller
    def index
    end

    def delete(oid)
    end

    def update(oid)
    end
    
    def create
    end
    
    def self.respond_to_action_or_template?(a)
      instance_methods.include?(a)
    end
  end

  class Link::Comment::Controller
    def self.respond_to_action_or_template?(a)
      instance_methods.include?(a)
    end
  end

  class RootController
    def index
    end

    def feed(category)
    end
    
    def self.respond_to_action_or_template?(a)
      instance_methods.include?(a)
    end
  end

  Template.root = File.expand_path(File.join('..', 'public'))
  
  def setup
    @d = Dispatcher.new

    @d['/'] = RootController
    @d['/links'] = Link::Controller
    @d['/links/comments'] = Link::Comment::Controller
  end
  
  def teardown
    @d = nil
  end

  def test_initialize
    dis = Dispatcher.new(RootController)
    assert_equal RootController, dis['/']
  end
  
  def test_dispatch
    r = [Link::Controller, "index_action", "category=1", [], ".html"]
    assert_equal r, @d.dispatch('/links/index.html?category=1')

    r = [RootController, "feed_action", nil, ["world"], ""]
    assert_equal r, @d.dispatch('/feed/world')

    r = [RootController, "feed_action", nil, ["zuper", "duper", "world"], ".xml"]
    assert_equal r, @d.dispatch('/feed/zuper/duper/world.xml')

    r = [RootController, "feed_action", "oid=2;test=1", ["zuper", "duper", "world"], ".xml"]
    assert_equal r, @d.dispatch('/feed/zuper/duper/world.xml?oid=2;test=1')

    r = [Link::Controller, "delete_action", nil, ["1"], ""]
    assert_equal r, @d.dispatch('/tralala?oid=1') rescue nil

    r = [Link::Controller, "delete_action", nil, ["1"], ""]
    assert_equal r, @d.dispatch('/links/1', :delete)

    r = [Link::Controller, "update_action", nil, ["1"], ""]
    assert_equal r, @d.dispatch('/links/1', :put)

    r = [Link::Controller, "index_action", nil, [], ""]
    assert_equal r, @d.dispatch('/links', :get)

    r = [Link::Controller, "index_action", nil, [], ".xml"]
    assert_equal r, @d.dispatch('/links/index.xml', :get)

    r = [Link::Controller, "create_action", nil, [], ""]
    assert_equal r, @d.dispatch('/links', :post)

    r = [Link::Controller, "create_action", "great=2;stuff=1", [], ""]
    assert_equal r, @d.dispatch('/links?great=2;stuff=1', :post)

    r = [RootController, "index_action", nil, [], ""]
    assert_equal r, @d.dispatch('/')
  end

end

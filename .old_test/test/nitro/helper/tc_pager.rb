require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'

require 'nitro/helper/pager'

class TC_Pager < Test::Unit::TestCase # :nodoc: all
  include Nitro
  include Nitro::PagerHelper

  class RequestMock < Hash
    attr_accessor :query
    
    def initialize
      @query = {}
    end
    
    def get(k, default)
      return self[k] || default
    end
  end
  
  def request
    RequestMock.new
  end
  
  def test_all
    stuff = [1, 2, 3, 4, 5, 6, 7, 8, 9]

    items, pager = paginate(stuff, :per_page => 2)
    assert_equal 2, items.size
    assert_equal 9, pager.total_count
  end
  
end

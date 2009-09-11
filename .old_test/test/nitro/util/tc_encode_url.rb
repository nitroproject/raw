require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'
require 'ostruct'

require 'glue'
require 'glue/logger'
require 'nitro'
require 'nitro/util/encode_url'

class TC_EncodeUrl < Test::Unit::TestCase # :nodoc: all
  include Nitro

  class FirstController < Nitro::Controller
    def list
    end
    public :encode_url
  end

  class SecondController < Controller
    attr_reader :aqflag, :tflag

    def self.setup_template_root(path)
      @template_root << File.expand_path(File.join(Nitro::LibPath, "../test/public/#{path}"))
    end   

    def list
      @aqflag = true 
    end

    def another(oid)
      # nop
    end
  end

  class Dummy
  end
  
  class Article
    attr_accessor :oid
    
    def initialize(oid)
      @oid = oid
    end
  end
  
  class Article::Controller < Nitro::Controller
    def delete(oid)
    end
  end

  class TestEncoder
    include Nitro::EncodeUrl
    public :encode_url
  end

  def setup
    @disp = Dispatcher.new '/first'  => FirstController,
                           '/second' => SecondController,
                           '/articles' => Article::Controller
    @conf = OpenStruct.new
    @conf.dispatcher = @disp
    Thread.current[:CURRENT_CONTEXT] = @conf
  end

  def test_encode
    t = TestEncoder.new

    assert_equal 'test', t.encode_url('test')
    assert_equal '/first/list', t.encode_url(FirstController, :list)
  
  end

  def test_controller_encode
    t = FirstController.new(@conf)
    
    assert_equal '/first/list', t.encode_url(:list)
  
    assert_equal '/articles/read', t.encode_url(Article, :read)

    assert_raises(NameError) { t.encode_url(Dummy, :read) }
    
    a = Article.new(5)
    assert_equal '/articles/read?oid=5', t.encode_url(a, :read) 
    assert_equal '/articles/delete/5', t.encode_url(a, :delete) 
  end  
end

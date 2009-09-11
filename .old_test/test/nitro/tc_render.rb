require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'

require 'nitro'
require 'nitro/render'
require 'nitro/session'
require 'nitro/context'
require 'facets/more/mock'

class TestRender < Test::Unit::TestCase # :nodoc: all
  include Nitro

  class ContextMock < Mock
    mock :response_headers, {}
    mock :host_url, 'http://www.nitroproject.org'
  end

  class TestController < Controller
  end

  class CallController < Controller
    def return_session
      session[:CALL_STACK].inspect
    end

    def needs_login
      call "login"
    end
    
    def login
      answer()
    end
  end

  @@session = Session.new
  def handle_request(url, value)
    conf = OpenStruct.new
    disp = Nitro::Dispatcher.new('/' => CallController)
    conf.dispatcher = disp
    @ctx = Nitro::Context.new(conf)
    @ctx.headers = { 'REQUEST_METHOD' => 'GET' }
    @ctx.params = {}
    @ctx.instance_variable_set '@session', @@session
    
    if value[:in]
      @ctx.in = value.delete(:in)
      @ctx.headers['CONTENT_LENGTH'] = value.delete(:in_size) || @ctx.in.size
    end
    
    if value[:method]
      @ctx.headers['REQUEST_METHOD'] = value[:method].to_s
    end
    
    if value['CONTENT_TYPE']
      @ctx.headers['CONTENT_TYPE'] = value.delete('CONTENT_TYPE')
    end
    
    @ctx.headers['REQUEST_URI'] = url
    
    if (!@ctx.query_string || @ctx.query_string.empty?) and @ctx.uri =~ /\?/
      @ctx.headers['QUERY_STRING'] = @ctx.uri.split('?').last
    end

    Nitro::Cgi.parse_params(@ctx)
    Nitro::Cgi.parse_cookies(@ctx)
    
    @ctx.render url

    #retrieve the stuff from @out again as a hash
    result = @ctx.out
    
    return result
  end

  def setup
    ctx =  ContextMock.new
    @controller = TestController.new(ctx)
  end

  def teardown
    @controller = nil
  end

  def test_redirect
    # relative url, the controller base_url is prepended (uh, really?)
    redirect 'hello'
    assert_equal 'http://www.nitroproject.org/hello', @controller.context.response_headers['location']

    # absolute url, use as is.
    redirect '/main'
    assert_equal 'http://www.nitroproject.org/main', @controller.context.response_headers['location']

    # http://, use as is.
    redirect 'http://www.gmosx.com/info'
    assert_equal 'http://www.gmosx.com/info', @controller.context.response_headers['location']

    redirect 'edit/Home'
    assert_equal 'http://www.nitroproject.org/edit/Home', @controller.context.response_headers['location']

    redirect '/edit/Home'
    assert_equal 'http://www.nitroproject.org/edit/Home', @controller.context.response_headers['location']    
  end

  def redirect(*args)
    begin
      @controller.send :redirect, *args
    rescue Nitro::RenderExit
    end
  end
  
  def test_call
    handle_request('/needs_login', {})
    assert_equal ['/needs_login'], eval(handle_request('/return_session', {}))
    handle_request('/login', {})
    assert_equal [], eval(handle_request('/return_session', {}))
  end
  
end

require File.join(File.dirname(__FILE__), 'CONFIG.rb')

$DBG = true

require 'test/unit'
require 'ostruct'

require 'nitro'
require 'nitro/cgi'


class String
  def clear
    gsub!(/.*/m, '')
  end
end

class TC_ControllerParams < Test::Unit::TestCase # :nodoc: all
  
  module Common
    def return_results *arguments
      from = caller[0][/`.*?'/][1..-2].intern
      hash = {}
      request.params.each do |k,v|
        hash[k] = if v.kind_of?(Tempfile) || v.kind_of?(StringIO) || v.kind_of?(IO)
          { :filename => v.original_filename, :size => v.size }
        else
          v
        end
        request.params = hash
      end
      
      @out.clear
      @out << {
        :action => from,
        :params => request.params,
        :arguments => arguments,
        :klass => self.class,
        :method => request.method
      }.inspect
    end
    private :return_results
  end # end module Common
  
  class TestController < Nitro::Controller
    include Common
    
    def index
      return_results
    end
    
    # Arity 0
    
    def none
      return_results
    end
    
    # Arity 1 - 3

    def single(arg)
      return_results arg
    end

    def double(arg1, arg2)
      return_results arg1, arg2
    end

    def triple(arg1, arg2, arg3)
      return_results arg1, arg2, arg3
    end
    
    def double__foo(arg)
      return_results arg
    end
    
    # Arity -1
    
    def m1(*args)
      return_results *args
    end
    
    def m1_2(arg1 = nil, arg2 = nil)
      return_results arg1, arg2
    end
    
    # Arity -2
    
    def m2(klass, parent_symbol = nil, parent_oid = nil, *args)
      return_results klass, parent_symbol, parent_oid, args
    end
    
    def m2_2(klass, parent_symbol = nil, parent_oid = nil)
      return_results klass, parent_symbol, parent_oid
    end
    
    # Overridden by C2?
    
    def c2
      return_results
    end
    
    # Error handler
    
    def error
      "(error)"
    end
    
  end # end class TestController
  
  class TestController2 < Nitro::Controller
    include Common
    
    def index(arg1 = nil, arg2 = nil)
      return_results arg1, arg2
    end
    
  end # end class TestController2
  
  module TestTestController3Helper
    def login
      return_results
    end
  end
  
  class TestController3 < Nitro::Controller
    include Common
    include TestTestController3Helper
    
    def index(arg1)
      return_results arg1
    end
    
    def document(oid=nil, del=nil, add=nil)
      return_results oid, del, add
    end
    
    def post(one = nil)
      return_results one
    end
    
  end # end class TestController2
  
  
  class TestControllerRouter < Nitro::Controller
    include Common
    
    def routed_one(name)
      return_results name
    end
    ::Nitro::Router.add_rule :match => /^\/routed_one\/(.*)/, :controller => TestControllerRouter, :action => :routed_one, :param => :name
    
  end
  
  #
  # Defined assertions
  #
  
  # Check against reference hash, only compare available values
  
  def cmp(reference, checked)
    reference.each do |k,v|
      return false if checked[k] != v
    end
    
    return true
  end
  
  def handle_request(url, value)
    conf = OpenStruct.new
    disp = Nitro::Dispatcher.new(
      '/' => TestController, 
      '/c2' => TestController2,
      '/c3' => TestController3,
      '/c4' => TestControllerRouter)
    conf.dispatcher = disp
    @ctx = Nitro::Context.new(conf)
    @ctx.headers = { 'REQUEST_METHOD' => 'GET' }
    @ctx.params = {}
    @ctx.instance_variable_set '@session', {}
    
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
  
  def assert_request_good(url, value, message = nil)
    result = handle_request(url, value)
    
    message = build_message(message, "<?> returned error. \nResult: ?\nInstead of: ?", url, result, value)
    
    assert_block message do
      if result =~ /error/
        false
      else
        cmp(value, eval(result))
      end
    end
  end
  
  def assert_request_bad(url, value, message = nil)
    result = handle_request(url, value)
    
    message = build_message(message, '<?> did not return error.', url)
    assert_block message do
      result = @ctx.out
      
      result =~ /error/
    end
  end
  
  ###################################################################
  #  Simple Testcases
  ###################################################################

  def test_simple
    tests = {
      '/none' => {
        :action => :none,
        :params => {},
        :arguments => []
      },
      '/single/arg' => {
        :action => :single,
        :params => {},
        :arguments => ['arg']
      },
      '/double/arg1/arg2' => {
        :action => :double,
        :params => {},
        :arguments => ['arg1', 'arg2']
      },
      '/triple/arg1/arg2/arg3' => {
        :action => :triple,
        :params => {},
        :arguments => ['arg1', 'arg2', 'arg3']
      },
      # George: none hase no arity, so the following *IS* valid!
      '/none/one/two' => {
        :action => :none,
        :params => {},
        :arguments => []
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end

  def test_simple_params
    tests = {
      '/none/?first=one&second=two' => {
        :action => :none,
        :params => {'first' => 'one', 'second' => 'two'},
        :arguments => []
      },
      '/none/?first=one&second=two' => {
        :action => :none,
        :params => {'first' => 'one', 'second' => 'two'},
        :arguments => []
      },
      '/none/?first' => {
        :action => :none,
        :params => {'first' => nil},
        :arguments => []
      },
      '/none/?first&second' => {
        :action => :none,
        :params => {'first' => nil, 'second' => nil},
        :arguments => []
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end

  def test_simple_bad
    tests = {
      '/single' => {
        :action => :single,
        :params => {},
        :arguments => [],
        :errmsg => 'Too few arguments. Should be one.'
      },
      '/double/arg1' => {
        :action => :double,
        :params => {},
        :arguments => [],
        :errmsg => 'Too few arguments. Should be two.'
      },
      '/triple/arg1/arg2' => {
        :action => :triple,
        :params => {},
        :arguments => [],
        :errmsg => 'Too few arguments. Should be 3.'
      },
      '/triple/arg1/arg2/arg3/arg4' => {
        :action => :triple,
        :params => {},
        :arguments => [],
        :errmsg => 'Too many arguments. Should be 3.'
      }
    }
    
    tests.each do |url, value|
      assert_request_bad url, value, value.delete(:errmsg)
    end
  end

  def test_mixed
    tests = {
      '/single/foo?first=one&second=two' => {
        :action => :single,
        :params => {'first' => 'one', 'second' => 'two'},
        :arguments => ['foo']
      },
      '/double/foo/bar?first=one&second=two' => {
        :action => :double,
        :params => {'first' => 'one', 'second' => 'two'},
        :arguments => ['foo', 'bar']
      }
    }
  
    tests.each do |url, value|
      assert_request_good url, value
    end
  end

  def test_slashes
    tests = {
      '/single/foo' => {
        :action => :single,
        :params => {},
        :arguments => ['foo']
      },
      '/double/foo/bar' => {
        :action => :double__foo,
        :params => {},
        :arguments => []
      },
      '/double/foo/bar/' => {
        :action => :double,
        :params => {},
        :arguments => ['foo', 'bar']
      },
      '/double/foo/bar' => {
        :action => :double,
        :params => {},
        :arguments => ['foo', 'bar']
      },
      '/double/foo/bar/' => {
        :action => :double,
        :params => {},
        :arguments => ['foo', 'bar']
      },
      '/none' => {
        :action => :none,
        :params => {},
        :arguments => []
      },
      '/none/' => {
        :action => :none,
        :params => {},
        :arguments => []
      }
    }
  
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  ###################################################################
  #  Arity -2 tests
  ###################################################################

  def test_m2
    tests = {
      '/m2/OgModule/user/5' => {
        :action => :m2,
        :params => {},
        :arguments => ['OgModule', 'user', '5', []]
      },
      '/m2/OgModule' => {
        :action => :m2,
        :params => {},
        :arguments => ['OgModule', nil, nil, []]
      },
      '/m2/OgModule/' => {
        :action => :m2,
        :params => {},
        :arguments => ['OgModule', nil, nil, []]
      },
      '/m2/OgModule/user/5/more/garbage' => {
        :action => :m2,
        :params => {},
        :arguments => ['OgModule', 'user', '5', ['more', 'garbage']]
      },
      '/m2_2/OgModule/user/5' => {
        :action => :m2_2,
        :params => {},
        :arguments => ['OgModule', 'user', '5']
      },
      '/m2_2/OgModule' => {
        :action => :m2_2,
        :params => {},
        :arguments => ['OgModule', nil, nil]
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  def test_m2_bad
    tests = {
      '/m2_2/OgModule/user/5/foo/bar' => {
        :action => :m2_2,
        :params => {},
        :arguments => [],
        :errmsg => 'Too many arguments.'
      },
      '/m2_2/' => {
        :action => :m2_2,
        :params => {},
        :arguments => [],
        :errmsg => 'Not enough arguments.'
      },
      '/m2' => {
        :action => :m2,
        :params => {},
        :arguments => [],
        :errmsg => 'Not enough arguments.'
      }
    }
    
    tests.each do |url, value|
      assert_request_bad url, value, value.delete(:errmsg)
    end
  end
  
  ###################################################################
  #  Arity -1 Tests
  ###################################################################
  
  def test_m1
    tests = {
      '/m1_2/' => {
        :action => :m1_2,
        :params => {},
        :arguments => [nil, nil]
      },
      '/m1_2' => {
        :action => :m1_2,
        :params => {},
        :arguments => [nil, nil]
      },
      '/m1_2/One' => {
        :action => :m1_2,
        :params => {},
        :arguments => ['One', nil]
      },
      '/m1_2/One/Two' => {
        :action => :m1_2,
        :params => {},
        :arguments => ['One', 'Two']
      },
    }

    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  def test_sub_zero_mixed
    tests = {
      '/m1/OgModule/user/5?more=garbage' => {
        :action => :m1,
        :params => {'more' => 'garbage'},
        :arguments => ['OgModule', 'user', '5']
      },
      '/m2/OgModule/user/5?more=garbage' => {
        :action => :m2,
        :params => {'more' => 'garbage'},
        :arguments => ['OgModule', 'user', '5', []]
      },
      '/m2/OgModule?more=garbage' => {
        :action => :m2,
        :params => {'more' => 'garbage'},
        :arguments => ['OgModule', nil, nil, []]
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  ###################################################################
  #  Used Controller Tests
  ###################################################################
  
  def test_controllers
    tests = {
      '/c2' => {
        :action => :index,
        :klass => TestController2,
        :arguments => [nil, nil]
      },
      '/c2/' => {
        :action => :index,
        :klass => TestController2,
        :arguments => [nil, nil]
      },
      '/' => {
        :action => :index,
        :klass => TestController
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  def test_index_handling
    tests = {
      '/c2/One' => {
        :action => :index,
        :klass => TestController2,
        :arguments => ['One', nil]
      },
      '/c2/One/Two' => {
        :action => :index,
        :klass => TestController2,
        :arguments => ['One', 'Two']
      },
      '/c2/index/One' => {
        :action => :index,
        :klass => TestController2,
        :arguments => ['One', nil]
      },
      '/c2/index/One/Two' => {
        :action => :index,
        :klass => TestController2,
        :arguments => ['One', 'Two']
      },
      '/c3/index/One' => {
        :action => :index,
        :klass => TestController3,
        :arguments => ['One']
      },
      '/c3/One' => {
        :action => :index,
        :klass => TestController3,
        :arguments => ['One']
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  def test_index_handling_bad
    tests = {
      '/c2/One/Two/Three' => {
        :action => :index,
        :klass => TestController2
      },
      '/c2/index/One/Two/Three' => {
        :action => :index,
        :klass => TestController2
      },
      '/c3/One/Two' => {
        :action => :index,
        :klass => TestController3
      },
      '/c3' => {
        :action => :index,
        :klass => TestController3
      },
      '/c3/index' => {
        :action => :index,
        :klass => TestController3
      }
    }
    
    tests.each do |url, value|
      assert_request_bad url, value
    end
  end
  
  ###################################################################
  #  Test Bug Reports
  ###################################################################
  
  def test_bug_report_ray
    tests = {
      '/c3/document/new/1' => {
        :action => :document,
        :klass => TestController3,
        :arguments => ['new', '1', nil]
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  def test_bug_report_fabian
    tests = {
      '/c3/login' => {
        :action => :login,
        :klass => TestController3,
        :arguments => []
      }
    }
    
    assert TestController3.ancestors.include?(TestTestController3Helper)
    assert TestController3.instance_methods.include?('login')
    assert TestController3.action_methods.include?('login')
    
    tests.each do |url, value|
      assert_request_good url, value
    end
    
  end
  
  def test_bug_report_kartesus
    tests = {
      '/none' => {
        :action => :none,
        :klass => TestController,
        :arguments => [],
        :params => {"test_file_a" => {:size=>10028,
                                      :filename=>"test_case.txt"},
                    "test_file_b" => {:size=>10240,
                                      :filename=>"test_case.txt"},
                    "empty_field" => {:size=>0, :filename=>""}},
        :method => :post
      }
    }
  
    tests.each do |url, value|
      create_multipart(value)
      assert_request_good url, value
    end
  end
  
  ###################################################################
  #  Test Routed Parameters
  ###################################################################
  
  def test_routed_one
    tests = {
      '/routed_one/some/name/I/got/here...' => {
        :action => :routed_one,
        :klass => TestControllerRouter,
        :arguments => ['some/name/I/got/here...'],
        :params => {}
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  end
  
  ###################################################################
  #  Mix-in GET Parameter Tests
  ###################################################################
  
  def test_mixin_get_parameters
    ::Nitro::Compiler.mixin_get_parameters = true
    
    tests = {
      '/double?arg1=bar;arg2=foo' => {
        :action => :double,
        :params => {'arg1' => 'bar', 'arg2' => 'foo'},
        :arguments => ['bar', 'foo']
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  ensure
    ::Nitro::Compiler.mixin_get_parameters = false
  end
  
  ###################################################################
  #  Non-strict Action Calling Tests
  ###################################################################
  
  def test_non_strict_action_calling
    ::Nitro::Compiler.non_strict_action_calling = true
    
    tests = {
      '/double' => {
        :action => :double,
        :params => {},
        :arguments => [nil, nil]
      }
    }
    
    tests.each do |url, value|
      assert_request_good url, value
    end
  ensure
    ::Nitro::Compiler.non_strict_action_calling = false
  end
  
  ###################################################################
  #  Test POST Multipart
  ###################################################################
  
  def test_multipart
    tests = {
      '/c3/post' => {
        :action => :post,
        :klass => TestController3,
        :arguments => [nil],
        :params => {"test_file_a" => {:size=>10028,
                                      :filename=>"test_case.txt"},
                    "test_file_b" => {:size=>10240,
                                      :filename=>"test_case.txt"},
                    "empty_field" => {:size=>0, :filename=>""}},
        :method => :post
      },
      '/c3/post/1' => {
        :action => :post,
        :klass => TestController3,
        :arguments => ['1'],
        :params => {"test_file_a" => {:size=>10028,
                                      :filename=>"test_case.txt"},
                    "test_file_b" => {:size=>10240,
                                      :filename=>"test_case.txt"},
                    "empty_field" => {:size=>0, :filename=>""}},
        :method => :post
      },
      '/c3/post/1?more=data' => {
        :action => :post,
        :klass => TestController3,
        :arguments => ['1'],
        :params => {"test_file_a" => {:size=>10028,
                                      :filename=>"test_case.txt"},
                    "test_file_b" => {:size=>10240,
                                      :filename=>"test_case.txt"},
                    "empty_field" => {:size=>0, :filename=>""},
                    "more" => "data"},
        :method => :post
      }
    }
    
    tests.each do |url, value|
      create_multipart(value)
      assert_request_good url, value
    end
  end

  def create_multipart(options, boundary = "---------------------------15773515131648678014689318540")
    # MIME block close falls on read boundary, also contains an empty field.
    closure = "#{Nitro::Cgi::EOL}--#{boundary}--#{Nitro::Cgi::EOL}"
    block_size = Nitro::Cgi.buffer_size

    input = StringIO.new
    input << "--#{boundary}#{Nitro::Cgi::EOL}"
    input << "Content-Disposition: form-data; name=\"test_file_a\"; filename=\"test_case.txt\"#{Nitro::Cgi::EOL}Content-Type: application/octet-stream#{Nitro::Cgi::EOL}#{Nitro::Cgi::EOL}"
    fake_file_a = String.random(block_size - input.size - (closure.size/2))
    input << fake_file_a
    input_after_fake_file = input.size
    input << "#{Nitro::Cgi::EOL}--#{boundary}#{Nitro::Cgi::EOL}"

    #Boundary fell inbetween two reads?
    assert_equal((block_size > input_after_fake_file) && (block_size < input.size),true)

    input << "Content-Disposition: form-data; name=\"test_file_b\"; filename=\"test_case.txt\"#{Nitro::Cgi::EOL}Content-Type: application/octet-stream#{Nitro::Cgi::EOL}#{Nitro::Cgi::EOL}"
    fake_file_b = Tempfile.new("TCCGI")

    i = 0
    file_size = 1024*10 # 1MB    
    i += fake_file_b.write String.random(1024*10) while i < file_size

    fake_file_b.rewind
    input << fake_file_b.read
    fake_file_b.rewind
    input << "#{Nitro::Cgi::EOL}--#{boundary}#{Nitro::Cgi::EOL}"

    input << "Content-Disposition: form-data; name=\"empty_field\"#{Nitro::Cgi::EOL}#{Nitro::Cgi::EOL}"
    input << closure
    input.rewind
    
    options[:in] = input
    options[:in_size] = input.size
    options['CONTENT_TYPE'] = "multipart/form-data boundary=\"#{boundary}\""
  end
  
end

# Random data for multipart param test

class String
  class << self

    begin
      require 'inline'

      inline do |builder|
        builder.c_raw <<-EOS
          static VALUE rnd(int argc, VALUE* args, VALUE self)
          {
            if (!argc)
              rb_raise(rb_eArgError, "not enough arguments");
            if (argc > 0)
              Check_Type(args[0], T_FIXNUM);
            if (argc > 1)
              Check_Type(args[1], T_FIXNUM);

            int size = FIX2INT(args[0]);
            int seed = argc > 1 ? FIX2INT(args[1]) : 0;
            int i = 0;
            VALUE str = rb_str_new((char*)0, size);

            srandom(seed);

            for (; i < size; i++) {
              RSTRING(str)->ptr[i] = (char)(((random() % ('z' - ' ')) + ' '));
            }

            return str;
          }
        EOS
      end

      def random(size, seed = 22)
        return rnd(size.to_i, seed.to_i)
      end

    rescue Exception => e
      puts "please install Ruby::Inline (gem install RubyInline) to speed up this test"

      def random(size)
        s = String.new
        range = (' '..'z').to_a
        r_size = range.size
        for i in (0...size)
          s << range[Kernel.rand(r_size)] # ascii range
        end
        s
      end

    end

  end
end

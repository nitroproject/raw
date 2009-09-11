require "script/lib/spec"

require "facets/core/kernel/assign_with"

require "stringio"
require "tempfile"
require "socket"
require "ostruct"

require "raw/cgi"
require "raw/cgi/cookie"

require File.join(File.dirname(__FILE__),"helper/string/random")


class User; attr_accessor :name, :password; end

describe Raw::Cgi do
  describe "parse_query_parameters" do

    it "should correctly parse name=value pairs divided by semicolon" do
      qs = "name=tml;id=12354"
      params = Raw::Cgi.parse_query_string(qs)
      params.size.should == 2
      params["name"].should == "tml"
      params["id"].should == "12354"
    end

    it "should be empty when parsing an empty string" do
      params = Raw::Cgi.parse_query_string("")
      params.should be_empty
    end

    it "should be empty when given nil" do
      params = Raw::Cgi.parse_query_string(nil)
      params.should be_empty
    end

    it "should be possible to rely on ordering of the parameters" do
      param_keys = ["name", "id", "foo", "bar", "baz"]
      qs = "name=tml&id=12354&foo=bar&bar=foo&baz=i"
      params = Raw::Cgi.parse_query_string(qs)
      params.keys.should == param_keys
    end

    it "should convert a name with array brackets into an array" do
      qs = "name=tml;arr[]=1;arr[]=2;arr[]=3"
      params = Raw::Cgi.parse_query_string(qs)
      params.size.should == 2
      params["arr"].size.should == 3
      (1..3).each do |n|
        params["arr"][n-1].should == n.to_s
      end
    end
    
    it "should be possible to use assign_with on User with Hash" do
      user = User.new
      user.assign_with("name" => "gmosx", "password" => "hello")
      user.name.should == "gmosx"
      user.password.should == "hello"
    end

    it "should support Scriptaculous syntax, e.g. user[name]=gmosx" do
      qs = "other=1;user[name]=gmosx;user[password]=hello"
      params = Raw::Cgi.parse_query_string(qs)
      params.size.should == 2
      u = params["user"]
      u["name"].should == "gmosx"
      u["password"].should == "hello"
    end
  end


  describe "parse_cookies" do
    it "should parse 'HTTP_COOKIE' from the Context" do
      context = OpenStruct.new
      context.env = {}
      context.env["HTTP_COOKIE"] = "nsid=123; nauth=gmosx:passwd"
      Raw::Cgi.parse_cookies(context)
      context.cookies.size.should == 2
      context.cookies["nsid"].should == "123"
    end

    it 'should join multiple values with the same key with "\0"' do
      context = OpenStruct.new
      context.env = {}
      context.env["HTTP_COOKIE"] = "nsid=123; nsid=23123"
      cookies = Raw::Cgi.parse_cookies(context)
      context.cookies.size.should == 1
      context.cookies["nsid"].should == "123" + "\0" + "23123"
    end
  end

  describe "response_headers" do
    it "should return a header with the given status, cookies and headers" do
      ctx = OpenStruct.new
      ctx.status = 200
      ctx.response_cookies = {
        "nsid" => Raw::Cookie.new("nsid", "1233"),
        "nauth" => Raw::Cookie.new("nauth", "gmosx")
      }
      ctx.response_headers = { 
        "Content-Type" => "text/html" 
      }

      res = "Status: 200 OK\r\nContent-Type: text/html\r\nSet-Cookie: nauthnauth=gmosx; Path=/\r\nSet-Cookie: nsidnsid=1233; Path=/\r\n\r\n"
      Raw::Cgi.response_headers(ctx).should == res
    end
  end


  describe "parse_multipart" do
    def make_context(input)
      context = OpenStruct.new
      context.in = input
      context.content_length = input.size
      context.env = { "HTTP_USER_AGENT" => "TestCase" }
      context.session = Hash.new
      class << context.session
        def sync
          true
        end
      end
      context
    end

    it "should work, this needs refactoring" do
      # MIME block close falls on read boundary, also contains an empty field.
      boundary = "---------------------------15773515131648678014689318540"
      closure = "#{Raw::Cgi::EOL}--#{boundary}--#{Raw::Cgi::EOL}"
      block_size = Raw::Cgi.buffer_size
      
      input = StringIO.new
      input << "--#{boundary}#{Raw::Cgi::EOL}"
      input << "Content-Disposition: form-data; name=\"test_file_a\"; filename=\"test_case.txt\"#{Raw::Cgi::EOL}Content-Type: application/octet-stream#{Raw::Cgi::EOL}#{Raw::Cgi::EOL}"
      fake_file_a = String.random(block_size - input.size - (closure.size/2))
      input << fake_file_a
      input_after_fake_file = input.size
      input << "#{Raw::Cgi::EOL}--#{boundary}#{Raw::Cgi::EOL}"

      #Boundary fell inbetween two reads?
      block_size.should > input_after_fake_file
      block_size.should < input.size
      
      input << "Content-Disposition: form-data; name=\"test_file_b\"; filename=\"test_case.txt\"#{Raw::Cgi::EOL}Content-Type: application/octet-stream#{Raw::Cgi::EOL}#{Raw::Cgi::EOL}"
      fake_file_b = Tempfile.new("TCCGI")

      i = 0
      file_size = 1024*1024*10 # 10MB    
      i += fake_file_b.write String.random(1024*10) while i < file_size

      fake_file_b.rewind
      input << fake_file_b.read
      fake_file_b.rewind
      input << "#{Raw::Cgi::EOL}--#{boundary}#{Raw::Cgi::EOL}"
      
      input << "Content-Disposition: form-data; name=\"empty_field\"#{Raw::Cgi::EOL}#{Raw::Cgi::EOL}"
      input << closure
      input.rewind
      start = Time.now
      params = Raw::Cgi.parse_multipart(make_context(input), boundary)
      duration = Time.now - start
      #    puts "\nparse_multipart took: #{duration} seconds\n"
      params["test_file_a"].to_s.should == fake_file_a.to_s
      params["test_file_b"].to_s.should == fake_file_b.read
      params["empty_field"].to_s.should == String.new
    end
  end
end

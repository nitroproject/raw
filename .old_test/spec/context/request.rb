require "script/lib/spec"

require "raw/context/request"

module Raw
  describe Request do
    class DummyRequest 
      include Request
      
      def initialize
        @headers = {}
        @post_params = @get_params = {}
      end
    end
  
    before do 
      @req = DummyRequest.new
    end

    it "should split the hostname into domain / subdomains" do
      @req.headers['HTTP_HOST'] = 'www.nitroproject.org'

      @req.domain.should == "nitroproject.org"
      @req.subdomains.first.should == "www"
    end

    it "should support different top level domain lengths" do
      @req.headers['HTTP_HOST'] = 'www.nitroproject.co.uk'
      @req.domain(2).should == "nitroproject.co.uk"
    end

    it "should set the xhr? predicate if requested with XMLHttpRequest" do
      @req.headers['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
      @req.xhr?.should == true
    end

    it "should find out that it's a POST with content type application/x-yaml and report this via Request#yaml_post? " do
      @req.headers['REQUEST_METHOD'] = 'POST'      
      @req.headers['CONTENT_TYPE'] = 'application/x-yaml'
      @req.yaml_post?.should == true
    end

    it "should find out that it's a POST with content type text/xml and report this via Request#xml_post? " do
      @req.headers['REQUEST_METHOD'] = 'POST'
      @req.headers['CONTENT_TYPE'] = 'text/xml'
      @req.xml_post?.should == true
    end

    it "should behave like a hash with #[], #[]= and #has?" do
      @req.headers['REQUEST_METHOD'] = 'GET'
      @req['test'] = 'hello'
      @req['test'].should_not be_nil
      @req['test'].should == "hello"
      @req.has?('test').should == true
    
      @req.has?('phantom').should == false
    
      @req['bug'] = nil
      @req.has?('bug').should == true
    end

    it "should recognize IP addresses intended for private use" do
      local_ips = ["192.168.1.1", "192.168.20.1", "192.168.99.1", "192.168.200.1", "192.168.21.245", "192.168.90.34", "192.168.254.254", "172.16.1.1", "172.18.1.1", "172.31.254.1", "172.21.1.254", "10.16.1.1", "10.0.1.1", "10.254.1.254", "10.192.1.192", "10.254.254.254", "10.10.10.10"]
      local_ips.map { |ip| @req.local_net?(ip) }.all?.should == true
    end

    it "should recognize public IP addresses" do
      not_local_ips = ["191.168.1.1", "192.169.20.1", "193.168.254.254", "172.15.1.1", "171.18.1.1", "172.32.0.0", "173.21.1.254", "11.16.1.1", "66.249.93.104", "72.14.221.104", "66.102.9.104", "17.254.3.183", "207.46.250.119", "207.46.130.108", "207.68.160.190", "65.54.240.126", "213.199.144.151", "65.55.238.126"]
      

      not_local_ips.map { |ip| ! @req.local_net?(ip) }.all?.should == true
    end

    after do
      @req = nil
    end
  end

end

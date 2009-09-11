require "uri"
require "net/http"

require "xmlsimple"

require "facets/hash/stringify_keys"

require "raw/util/xml"

# Encapsulates a Web Service.

class WebService

  attr_accessor :connection
  attr_accessor :host, :port
  
  # Initialize.
  
  def initialize(uri)
    uri = URI.parse(uri)
    @host, @port = uri.host, uri.port
    connect!
  end
  
  # Use SSL to access the service?
  
  def ssl?
    @port == 443
  end
  
  # Connect to  the service endpoint.
  
  def connect!
    @connection = Net::HTTP.new(@host, @port)
#   @connection.use_ssl = ssl?
    @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if ssl?
  end
  
  # Perform a post request.
  # You can pass the special key :FORMAT to set the serialization
  # format. By default yaml is used.
     
  def post(path, params = {})
    format = params.delete(:FORMAT) || :yaml
    data = params.stringify_keys.send("to_#{format}")
   
    res = @connection.post(path, data, "CONTENT-TYPE" => "application/#{format}")

    if res.code == "200"
      case format
      when :xml
        res = Hash.new.from_xml(res.body)
      when :json
        res = JSON.parse(res.body)
      when :yaml
        res = YAML.load(res.body)      
      end
    else
      raise "Error occured (#{res.code}): #{res.body}"
    end

    return res
  end
  alias_method :request, :post
  alias_method :r, :post
  
  # Perform a get request.
  
  def get
  end
  
end


module RPC
  
  def remote_post(host, path, params = {})
    WebService.new(host).post(path, params)
  end
  
end

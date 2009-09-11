require "ostruct"

require "test/unit"
require "test/unit/assertions"
require "rexml/document"

require "raw/test/context"

module Test::Unit

class TestCase
  include Raw

  def reset_context
    @context_config = OpenStruct.new(
      :dispatcher => Raw::Dispatcher.new(Nitro::Server.map)
    )
    @context = Raw::Context.new(@context_config)
  end

  # Send a request to the controller. Alternatively you can use
  # the request method helpers (get, post, ...)
  #
  # === Options
  #
  # :uri, :method, :headers/:env, :params, :session

  def process(options = {})
    unless options.is_a? Hash
      options = { :uri => options.to_s }
    end

    uri = options[:uri]
    uri = "/#{uri}" unless uri =~ /^\//

    reset_context unless @context
    context = @context
    if @last_response_cookies
      @last_response_cookies.each do |cookie|
        context.cookies.merge! cookie.name => cookie.value
      end
    end
    context.headers = options[:headers] || options[:env] || {}
    context.headers['REQUEST_URI'] = uri
    context.headers['REQUEST_METHOD'] = options.fetch(:method, :get).to_s.upcase
    context.headers['REMOTE_ADDR'] ||= '127.0.0.1'
    if ((:get == options[:method]) and (options[:params]))
      context.headers['QUERY_STRING'] = options[:params].collect {|k,v| "#{k}=#{v}"}.join('&')
    end
    context.params = options[:params] || {}
    context.cookies.merge! options[:cookies] if options[:cookies]
    context.session.merge! options[:session] if options[:session]

    context.render(context.path)
    @last_response_cookies = context.response_cookies
    return context.body
  end

  #--
  # Compile some helpers.
  #++

  for m in [:get, :post, :put, :delete, :head]
    eval %{
      def #{m}(options = {})
        unless options.is_a? Hash
          options = { :uri => options.to_s }
        end
        options[:method] = :#{m}
        process(options)
      end
    }
  end

end

end


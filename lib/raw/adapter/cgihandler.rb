require "raw/cgi"
require "raw/adapter"

module Raw

# A Handler for the CGI and FastCGI adapters.

class CgiHandler
  include AdapterHandlerMixin

  def initialize(application)
    @application = application
  end

  def process(cgi, inp, out)
    context = Context.new(@application)

    unless inp.respond_to?(:rewind)
      # The module Request#raw_body requires a rewind method,
      # so if the input stream doesn't have one, *cough* FCgi,
      # we convert it to a StringIO.

      inp = StringIO.new(inp.read.to_s) # if read returns nil, to_s makes it ""
    end

    context.in = inp
    context.headers = cgi.env

    #--
    # gmosx: only handle nitro requests.
    # gmosx: QUERY_STRING is sometimes not populated.
    #++

    if context.query_string.empty? and context.uri =~ /\?/
      context.headers["QUERY_STRING"] = context.uri.split("?").last
    end

    output = handle_context(context)

    out.print( Cgi.response_headers(context) )
    out.print( output )
      
    context.close    
  end

end
end

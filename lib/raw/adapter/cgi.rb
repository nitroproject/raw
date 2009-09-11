require "raw/adapter"
require "raw/adapter/cgihandler"

class CGI # :nodoc: all
  def env  # like FastCGI
    ENV
  end
end

# No multi-threading.

Og.thread_safe = false if defined?(Og) and Og.respond_to?(:thread_safe)


module Raw

# A plain CGI adapter. 
#
# To be used only in development environments, this adapter
# is *extremely* slow for live/production environments. It is
# provided for the sake of completeness.
#
# There is really no good reason to use this adapter. If you
# can't use Mongrel, then FastCGI might be a viable alternative.

class CgiAdapter < Adapter

  def start(application)
    cgi = CGI.new
    handler = CgiHandler.new(application)
    handler.process(cgi, $stdin, $stdout)
  end

end

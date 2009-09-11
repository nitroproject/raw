require 'cgi'
require 'fcgi'

require "raw/context"
require "raw/dispatcher"
require "raw/adapter/cgihandler"
require "raw/adapter"

# Speeds things up, more comaptible with OSX.

Socket.do_not_reverse_lookup = true

# No multi-threading.

Og.thread_safe = false if defined?(Og) and Og.respond_to?(:thread_safe)

module Raw

# FastCGI Adaptor. FastCGI is a language independent, 
# scalable, open extension to CGI that provides high 
# performance without the limitations of server 
# specific APIs.
#
# Altough FastCGI is a notable improvement over CGI, the
# recommended way of running Nitro is using a proxy setup
# with Apache or Lighttpd proxying to one or more Mongrel
# backend servers.
#
# === Sessions
#
# As FCGI is process based, you have can't use the default
# in-memory session store. For production web sites you should
# use the drb session store. Moreover, there is no need for 
# DB connection pooling in Og.
#

class FastcgiAdapter < Adapter

  def start(application)
    FCGI.each do |cgi|
      begin
        CgiHandler.new(application).process(cgi, cgi.in, cgi.out)
        cgi.finish
      end
    end
  end

end

end

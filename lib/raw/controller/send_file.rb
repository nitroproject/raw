require "raw/render"

module Raw

module Render

  # Send a file download to the client.
  #
  # Like render and redirect, the action is exited upon calling
  #
  # [+fname+]  That name of the file
  # [+path+]   Specifying true mean fname contains the full path.
  #     The default, false, uses Server.public_root as the path.
  #
  # [+return+] true on success, false on failure
  #
  # === Examples
  #
  # require "raw/render/send_file"
  #
  # class MyController < Nitro:Controller
  #   def download(fname)
  #     send_file(fname)
  #   end
  # end
  #
  # class MyController < Nitro:Controller
  #   def download
  #     send_file("/etc/password", true)
  #   end
  # end
  
  def send_file(fname = nil, fullpath = false)
    fname = fullpath ? fname : "#{@context.application.public_dir}/#{fname}"
    f = File.open(fname, "rb")
    @context.response_headers["Cache-control"] = "private"
    @context.response_headers["Content-Length"] = "#{File.size?(f) || 0}"
    @context.response_headers["Content-Type"] = "application/force-download"
    @context.output_buffer = f
    raise RenderExit
  end
  alias_method :sendfile, :send_file

end

end

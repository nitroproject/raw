require "raw/adapter/webrick"

module Raw

class WebrickAdapter < Adapter

  def setup(server)
    if $record_session_filename
      vcr_record($record_session_filename)
    end

    if $playback_session_filename
      vcr_playback($playback_session_filename)
    end
  end

  # Enables session recording. The recorded data can be used
  # for automatic app testing by means of the playback mode.

  def vcr_record(filename = "session.yaml")
    info "Recording application server session to '#{filename}'."

    require "facets/file/create"

    $record_session = []
    $last_record_time = Time.now

    Raw::WebrickHandler.class_eval do
      def do_GET(req, res)
        record_context(req, res)
        handle(req, res)
      end
      alias_method :do_POST, :do_GET

      def record_context(req, res)
        delta = Time.now - $last_record_time
        $last_record_time = Time.now
        $record_session << [delta, req, res]
      end
    end

    at_exit do
      File.create(filename, YAML.dump($record_session))
    end
  end

  # Playback a recorded session. Typically used for testing.

  def vcr_playback(filename = "session.yaml")
    info "Playing back application server session from '#{filename}'."

    $playback_session = YAML.load_file(filename)
    $playback_exception_count = 0

    WEBrick::HTTPServer.class_eval do
      def start(&block)
        run(nil)
      end

      def run(sock)
        while true
          delta, req, res = $playback_session.shift

          if delta
            sleep(delta)
            begin
              handle(req, res)
            rescue Object => ex
              $playback_exception_count += 1
              p "---", ex
            end
          else
            return
          end
        end
      end
    end

    at_exit do
      puts "\n\n"
      puts "Playback raised #$playback_exception_count exceptions.\n"
      puts "\n"
    end
  end

end

end


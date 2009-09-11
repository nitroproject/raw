require "tidy"

module Raw

# Use this filter to cleanup the generated html.
#--
# DON'T USE YET
#++

class TidyFilter

  PATH = `locate libtidy.so`.strip

  def self.apply(source)
    ::Tidy.path = PATH

    defaults = {
      :output_xml => true,
      :input_encoding => :utf8,
      :output_encoding => :utf8,
      :indent_spaces => 2,
      :indent => :auto,
      :markup => :yes,
      :wrap => 500
    }

    ::Tidy.open(:show_warnings => true) do |tidy|
      for key, value in defaults
        tidy.options.send("#{key}=", value.to_s)
      end
      tidy.clean(source)
    end
  rescue LoadError => ex
    error ex
    error "cannot load 'tidy', please `gem install tidy`"
    error "you can find it at http://tidy.rubyforge.org/"
  end

  def apply(source)
    self.class.apply(source)
  end
end

end

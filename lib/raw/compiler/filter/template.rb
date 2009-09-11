require "facets/settings"

module Raw

# The Nitro Template system. Nitro templates are xhtml and
# ruby friendly.

class Template

  # The default template dir.

  if File.exist? "template"
    template_dir = "template"
  else
    template_dir = "app/template"
  end
    
  setting :root_dir, :default => template_dir, :doc => "The default template dir"

  # Strip xml comments from templates?
  
  setting :strip_xml_comments, :default => false, :doc => "Strip xml comments from templates?"

end

# The basic Nitro Template filter.

class TemplateFilter

  # Set some pretty safe delimiters for templates.

  START_DELIM = "%{"
  END_DELIM = "}\n"

  # Convert a template to actual Ruby code, ready to be 
  # evaluated.
  #
  # [+source+] 
  #    The template source as a String.
  #
  # [+buffer+]
  #    The variable to act as a buffer where the ruby code
  #    for this template will be generated. Passed as a
  #    String.
  
  def apply(source, buffer = "@out")
    source = source.dup
    
    # Strip the xml header! (interracts with the following gsub!)

    source.gsub!(/<\?xml.*\?>/, "")

    # Transform include instructions <include href="xxx" />
    # must be transformed before the processing instructions.
    # Useful to include fragments cached on disk
    #--
    # gmosx, FIXME: NOT TESTED! test and add caching.
    # add load_statically_included fixes.
    #++
    
    source.gsub!(/<include\s+href=["'](.*?)["']\s+\/>/, %[<?r File.read("\#{@dispatcher.root}/\\1") ?>])
    
    # xform render/inject instructions <render href="xxx" />
    # must be transformed before the processinc instructions.

    source.gsub!(/<(?:render|inject)\s+href=["'](.*?)["']\s+\/>/, %[<?r render "\\1" ?>])

    # Transform the processing instructions, use <?r as a marker.
    
    source.gsub!(/<\?r\s+(.*?)\s+\?>/m) do |code|
      "#{END_DELIM}#{$1.squeeze(' ').chomp}\n#{buffer} << #{START_DELIM}"
    end
    
    # Transform alternative code tags (very useful in xsl 
    # stylesheets).

    source.gsub!(/<ruby>(.*?)<\/ruby>/m) do |code|
      "#{END_DELIM}#{$1.squeeze(' ').chomp}\n#{buffer} << #{START_DELIM}"
    end
    
    # Also handle erb/asp/jsp style tags. Those tags *cannot* 
    # be used with an xslt stylesheet.
    #
    # Example:
    #   <% 10.times do %>
    #     Hello<br />
    #   <% end %>

    source.gsub!(/<%(.*?)%>/m) do |code|
      "#{END_DELIM}#{$1.squeeze(' ').chomp}\n#{buffer} << #{START_DELIM}"
    end

    # Alterative versions of interpolation (very useful in xsl 
    # stylesheets).
    #
    # Example: 
    #   Here is #\my_val\
    
    source.gsub!(/\#\\(.*?)\\/, '#{\1}')

    # Alternative for entities (useful in xsl stylesheets).
    #
    # Examples:
    #   %nbsp;, %rquo;

    source.gsub!(/%(#\d+|\w+);/, '&\1;')

    # Compile time ruby code. This code is evaluated when
    # compiling the template and the result injected directly
    # into the result. Usefull for example to prevaluate
    # localization. Just use the #[] marker instead of #{}.
    #
    # Example:
    #   This script was compiled at #[Time.now]
    
    source.gsub!(/\#\[(.*?)\]/) do |match|
      eval($1)
    end

    return "#{buffer} << #{START_DELIM}#{source}#{END_DELIM}"
  end


end

end

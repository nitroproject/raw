require "raw/util/markup"

module Raw

class MarkupFilter

  # Transform the markup macros.
  # Maps #(..) to :sanitize.
  # Maps #|..| to :markup.
  #
  # Additional markup macros:
  #
  # Maps ''..'' to #{...to_link}
  # Maps {{..}} to #{R ..}
  # Maps #<..> to #{R ..}
  
  def apply(source)
    source = source.dup
    
    source.gsub!(/\#\((.*?)\)/, '#{sanitize(\1)}')
    source.gsub!(/\#\|(.*?)\|/, '#{markup(\1)}')

    source.gsub!(/\'\'(.*?)\'\'/, '#{\1.to_link}')    
    source.gsub!(/\{\{(.*?)\}\}/, '#{R \1}')    
    source.gsub!(/\#\<(.*?)\>/, '#{R \1}')    
    
    return source
  end
  
end

end

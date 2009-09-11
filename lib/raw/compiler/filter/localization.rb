module Raw

# Transform localization macros.
#--
# TODO: add support for compile-time resolving
#++

class LocalizationFilter
  
  def apply(source)
    source = source.dup
    
    # handle symbols.
    
    source.gsub!(/\[\[\:(.*?)\]\]/, '#{@lc[\1]}')

    # handle strings.
     
    source.gsub!(/\[\[(.*?)\]\]/, '#{@lc["\1"]}')

    return source
  end
  
end

end

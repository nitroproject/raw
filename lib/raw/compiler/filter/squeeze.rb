module Raw

# Compress HTML markup.
 
class SqueezeFilter
  
  # Remove new lines. Typically used in live mode before the
  # TemplateFilter.
   
  def apply(source)
    source.gsub(/^(\s*)/m, "").gsub(/\n/, "").gsub(/\t/, " ").squeeze(" ")
  end
  
end
  
end

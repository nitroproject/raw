require "facets/openobject"

require "raw/compiler/filter/template"

module Raw

# A Mail template. Set any variables you would like to use in
# your mail template and just provide a .html template file.
#
# template.name = "gmosx"
# template.hello = "world"
# template.render("mail.html")
#
# mail.htmlx:
#
# Hello #{name},
# This is the hello variable: #{hello}
#
# The interpolated result:
#
# Hello gmosx,
# This is the hello variable: world

class MailTemplate < OpenObject

  def render(template)
    filter = TemplateFilter.new
    code = filter.apply(File.read(template))
    @out = ""
    eval(code)
    return @out
  end

end

end

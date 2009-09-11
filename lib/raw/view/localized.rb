require "raw/util/localization"

module Raw::Mixin

# Add localization support to a Controller. This localization
# system is cache friendly.

module Localized
  
private

  def resolve_locale
    locale = request.host_uri.gsub("http://", "").split(".").first
    if Localization.supports_locale? locale
      session[:LOCALE] = locale
    end

    set_locale()   
  end

  def set_locale
    @lc = Localization[session[:LOCALE] || Localization.default_locale]
  end
  
end

end


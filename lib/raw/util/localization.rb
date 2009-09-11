require "yaml"

# Represents a locale.
#--
# TODO: initialize translation map from a yaml file.
#++

class Locale

  # The localization map.

  attr_accessor :map
  
  def initialize(map)
    parse_hash(map)
  end

  # Transalte the given key.
  #
  # [+args+]
  #    An array of arguments. The first argument
  #    is the translation key. If additional arguments
  #    are provided they are used for sprintf 
  #    interpolation.
  #--
  # THINK: Possibly avoid the creation of the 
  #  array by making the api less elegant.
  #++

  def translate(*args)
    key = args.shift
    if xlated = @map[key]
      if xlated.is_a?(String)
        args.empty? ? xlated : sprintf(xlated, *args)
      else
        xlated.call(*args)
      end
    else
      return key
    end
  end
  alias_method :[], :translate

  class << self
  
    def set(locale)
      @@current = locale      
    end

    def get(locale)
      @@current
    end
    alias_method :current, :get
  
  end

private

  def parse_hash(map)
    @map = map
  end

  def parse_yaml(yaml)
    raise "Not implemented"
  end

end

# Localization support.
#
# Example:
#
#   locale_en = {
#     'See you' => 'See you',
#     :long_paragraph => 'The best new books, up to 30% reduced price',
#     :price => 'Price: %d %s',
#     :proc_price => proc { |value, cur| "Price: #{value} #{cur}" }
#   }
#
#   locale_de = {
#     'See you' => 'Auf wieder sehen',
#     :long_paragraph => 'Die besten neuer buecher, bis zu 30% reduziert',
#     ...
#   }
#
#   Localization.add(:en => locale_en, :de => locale_de)
#
#   lc = Localization.get
#   lc['See you'] -> See you
#   lc[:price, 100, 'euro'] -> Price: 100 euro
#   lc = Localization.get[:de]
#   lc['See you'] -> Auf wiedersehen
#
#   To make localization even more easier, a LocalizationAspect
#   is provide provided. Additional transformation macros are
#   provided if you require 'nitro/compiler/localization'

class Localization
  
  setting :default_locale, :default => "en", :doc => "The default locale"

  class << self
    
    # A hash of the available locales.

    attr_accessor :locales

    def add(map = {})
      for key, locale in map
        if locale.is_a?(String)
          # this is the name of the localization file.
          locale = YAML.load(File.read(locale))
        end
        @locales[key.to_s] = Locale.new(locale)
      end
    end
    alias_method :locales=, :add
        
    # Return the localization hash for the given
    # locale.

    def get(locale = Localization.default_locale)
      @locales[locale.to_s]
    end
    alias_method :locale, :get
    alias_method :[], :get

    # Is this locale supported?
    
    def has_locale?(locale)
      @locales.has_key?(locale.to_s)
    end
    alias_method :supports_locale?, :has_locale?
  
  end

  @locales = {}

end


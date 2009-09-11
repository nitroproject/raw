#--
# Autoload core Raw classes as needed. Potentially minimizes
# startup time and memory footprint, allows for cleaner source
# files, and makes it easier to move files around.
#++

if $DBG || defined?(Library)

  require "raw/model/sweeper"

  require "raw/view/pager"
  require "raw/view/pager"
  require "raw/view/localized"
  require "raw/view/model"
  require "raw/view/asset"

  require "raw/util/localization"
  require "raw/compiler/filter/localization"
  require "raw/view/localized"

else

  Raw::Mixin.autoload :Sweeper, "raw/model/sweeper"

  Raw::Mixin.autoload :Pager, "raw/view/pager"
  Raw::Mixin.autoload :PagerHelper, "raw/view/pager"
  Raw::Mixin.autoload :Localized, "raw/view/localized"
  Raw::Mixin.autoload :ModelUI, "raw/view/model"
  Raw::Mixin.autoload :AssetHelper, "raw/view/asset"

  Raw.autoload :Localization, "raw/util/localization"
  Raw.autoload :LocalizationFilter, "raw/compiler/filter/localization"
  Raw.autoload :Localized, "raw/view/localized"

end

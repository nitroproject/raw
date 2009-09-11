require 'cgi'

# WHY DO WE HAVE Og HERE?!!!

require 'og'
require 'og/relation/all'


#--
# TODO: find a better name!
# TODO: this is nitro request specific, should probably get moved
# into the Nitro directory.
#++

class AttributeUtils
  class << self

  #--
  # TODO: Add preprocessing.
  #++

  def set_attr(obj, name, value)
    obj.send("__force_#{name}", value)
  rescue Object => ex
    obj.instance_variable_set("@#{name}", value)
  end

  # Populate an object from a hash of values.
  # This is a truly dangerous method.
  #
  # Options:
  #
  # * name
  # * force_boolean

  def populate_object(obj, values, options = {})
    options = {
      :force_boolean => true
    }.update(options)

    # If a class is passed create an instance.

    obj = obj.new if obj.is_a?(Class)

    for sym in obj.class.serializable_attributes
      anno = obj.class.ann(sym)

      unless options[:all]
        # THINK: should skip control none attributes?
        next if sym == obj.class.primary_key or anno[:control] == :none or anno[:disable_control]
      end

      prop_name = sym.to_s

      # See if there is an incoming request param for this prop.

      if values.keys.include? prop_name

        prop_value = values[prop_name]

        # to_s must be called on the prop_value incase the
        # request is IOString.

        prop_value = prop_value.to_s unless prop_value.is_a?(Hash) or prop_value.is_a?(Array)

        # If property is a Blob don't overwrite current
        # property's data if "".

        break if anno[:class] == Og::Blob and prop_value.empty?

# already unescaped (fixes stupid + bug)
#       prop_value = CGI.unescape(prop_value)

        if anno[:class] == String and anno[:unfiltered] != true
          # html filter all strings by default.
          prop_value = prop_value.html_filter
        end
        if anno[:class] == Date
          set_attr(obj, prop_name, Date.parse(prop_value))
        elsif
 #         set_attr(obj, prop_name, CGI.unescape(prop_value))
           set_attr(obj, prop_name, prop_value)
        end

      elsif options[:force_boolean] and (anno[:class] == TrueClass or anno[:class] == FalseClass)
        # Set a boolean property to false if it is not in the
        # request. Requires force_boolean == true.

        set_attr(obj, prop_name, false)
        obj.send("__force_#{prop_name}", false)
      end
    end

    if options[:assign_relations]
      for rel in obj.class.relations
        unless options[:all]
          next if rel.options[:control] == :none or rel.options[:disable_control]
        end

        rel_name = rel.name.to_s

        # Renew the relations from values

        if rel.kind_of?(Og::RefersTo)
          if foreign_oid = values[rel_name]
            foreign_oid = foreign_oid.to_s unless foreign_oid.is_a?(Hash) or foreign_oid.is_a?(Array)
            foreign_oid = nil if foreign_oid == 'nil' or foreign_oid == 'none'
          end
          set_attr(obj, rel.foreign_key, foreign_oid) if values.has_key?(rel_name)
        elsif rel.kind_of?(Og::JoinsMany) || rel.kind_of?(Og::HasMany)
          if values.has_key?(rel_name)
            collection = obj.send(rel_name)
            collection.remove_all
            primary_keys = values[rel_name]
            primary_keys.each do |v|
              v = v.to_s
              next if v == "nil" or v == "none"
              collection << rel.target_class[v.to_i]
            end
          end
        end
      end
    end

    #--
    # gmosx, FIXME: this is a hack, will be replaced with proper
    # code soon. Used in WebFile at the moment.
    #++

    for callback in obj.class.assign_callbacks
      callback.call(obj, values, options)
    end if obj.class.respond_to?(:assign_callbacks)

    return obj
  end

  end
end

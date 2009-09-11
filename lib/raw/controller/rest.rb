require "facets/string"

module Raw::Mixin

# Include this module to your controllers to provide an initial
# REST interface. You can  consider this module a scaffolding
# aid to  get you going.

module RESTController

  def self.included(base)
    klass = base.ann(:self, :model)
    plural = klass.name.underscore.plural

    base.send(:define_method, :index) do
      instance_variable_set "@#{plural}", klass.all(:limit => 20)
    end

=begin
    base.module_eval do
      def index
        plural = base.name.underscore.plural
        instance_variable_set "@#{plural}", base.all(:limit => 20)
      end

      def view(oid)
        singular = base.name.underscore.singular
        instance_variable_set "@#{singular}", base[oid]
      end

      def new
        singular = base.name.underscore.singular
        instance_variable_set "@#{singular}", base.new
      end

      def edit(oid)
        singular = base.name.underscore.singular
        instance_variable_set "@#{singular}", base[oid]
      end

      def create
        user = request.assign(base.new)
        save(user)
      end

      def update
        obj = request.assign(base.new)
        save(obj)
      end

      def delete(oid)
        base.delete(oid)
        redirect_to_referer
      end

      private

      def save(obj)
        redirect_to_referer
      end
    end
=end
  end

end

end

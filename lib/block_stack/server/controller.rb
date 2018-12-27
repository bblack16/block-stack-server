module BlockStack
  class Controller < Server

    # Returns this controllers reference to the base server it is registered to
    # or nil if it is standalone.
    def self.base_server
      @base_server
    end

    # Sets the base_server that this controller is registered with. NEVER call
    # this method in your code.
    def self.base_server=(bs)
      @base_server = bs
    end

    # Overrides the controller method from Server so that controllers do not have
    # their own controllers.
    def self.controllers
      []
    end

    # Attempts to find a model matching this controller if the BlockStack::Model
    # class is loaded and if this controllers name follows the ModelController
    # naming convention.
    def self.model
      return @model if @model
      return nil unless defined?(BlockStack::Model)
      name = self.to_s.split('::').last.sub(/Controller$/, '')
      @model = BlockStack::Model.model_for(name.method_case.to_sym)
    end

    bridge_method :model

    # Sets the model for this controller to a specific class. This voids the
    # convention over configuration approach but may be necessary is some cases.
    def self.model=(mdl)
      raise ArgumentError, "Invalid model passed to #{self}. Must be inherited from BlockStack::Model, got #{mdl}." unless mdl < BlockStack::Model
      @model = mdl
    end

    # Shorthand for attaching the crud template group to this controller. This
    # should only be called if this controller has an associated Model.
    def self.crud(opts = {})
      opts[:model] = Model.model_for(opts[:model]) if opts[:model].is_a?(Symbol)
      self.model = opts[:model] if opts[:model]
      self.prefix = opts.include?(:prefix) ? opts[:prefix] : model.plural_name
      attach_template_group(:crud, *(opts[:ignore] || []))
      true
    end

    protected

    # Method missing is forwarded to the base_server.
    def method_missing(method, *args, &block)
      if base_server && base_server.respond_to?(method)
        base_server.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      base_server && base_server.respond_to?(method) || super
    end

    # Convenience method to call the Model.find method of the associated model.
    # This automatically uses the :id param of the controller to find the model.
    # TODO Allow params other than :id to be configured.
    def find_model
      return nil unless model
      model.find(params[:id])
    end

    # Same as find_model but automatically halts and returns a 404 if a match
    # is not found.
    def find_model!
      model = find_model
      return model if model
      halt 404, 'Not found'
    end
  end
end

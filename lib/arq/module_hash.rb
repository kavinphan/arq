# frozen_string_literal: true

module Arq
  # Allows for dot-accessing of modules.
  # Child modules are automatically wrapped and actions are called.
  class ModuleHash < Hash
    def initialize(mod, action_inst)
      super()

      @module = mod
      @action_inst = action_inst
    end

    def method_missing(method, *args, &block)
      wrap(@module.const_get(method.to_s.camelize))
    rescue NameError => _e
      super
    end

    def respond_to_missing?(method, include_private = false)
      @module.const_defined?(method.to_s.camelize.to_sym) || super
    end

    private

    # If the value is a Module, it's returned as a ModuleHash.
    def wrap(value)
      case value
      when Arq::Action
        @action_inst.call_other(value)
      when Module
        self.class.new(value, @action_inst)
      else
        value
      end
    end
  end
end

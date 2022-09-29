# frozen_string_literal: true

module Arq
  # Allows for dot-accessing of modules and running of actions.
  # Child modules are automatically wrapped and actions are called.
  class ActionModuleHash < Hash
    # Calls action or wraps in hash class if module.
    def self.from(obj, action_inst)
      case obj
      when Arq::Action
        action_inst.call_other(obj)
      when Module
        new(obj, action_inst)
      else
        raise "Object must be an Action or Module"
      end
    end

    def initialize(mod, action_inst)
      super()

      @module = mod
      @action_inst = action_inst
    end

    def method_missing(method, *args, &block)
      # Format method as module path.
      formatted = method.to_s.camelize

      # Attempt to find object.
      obj = if Object.const_defined?(formatted)
              Object.const_get(formatted)
            else
              return super
            end

      self.class.from(obj)
    end

    def respond_to_missing?(method, include_private = false)
      @module.const_defined?(method.to_s.camelize.to_sym) || super
    end
  end
end

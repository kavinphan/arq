# frozen_string_literal: true

module Arq
  # Module to extend to create an action.
  # Class methods are used to configure the action itself.
  # Instance methods are exposed to the block passed into `run`.
  module Action
    def self.extended(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    def self.included(_base)
      raise "`Arq::Action` should be `extended`"
    end

    # Methods and fields exposed to configure the action.
    module ClassMethods
      # Runs the stored block with variables from the provided context.
      def call(ctx = Arq::Context.new)
        ctx = transform_input_context(ctx)

        inst = new(ctx)
        inst.run

        ctx
      end

      def params_list
        @params_list ||= []
      end

      def returns_list
        @returns_list ||= []
      end

      def run_block
        @run_block ||= nil
      end

      private

      # Ensures that a valid context is passed and returned.
      # Acceptable values are Context or Hash objects.
      def transform_input_context(ctx)
        case ctx
        when Arq::Context
          ctx
        when Hash
          Arq::Context.new(ctx)
        else
          raise Arq::InvalidContextParameterError
        end
      end

      def params(*keys)
        params_list.concat(keys).compact
      end

      def returns(*keys)
        returns_list.concat(keys).compact
      end

      def run(&block)
        return "Block required" unless block_given?

        @run_block = block
      end
    end

    # Methods and fields exposed to the run block.
    module InstanceMethods
      def initialize(ctx)
        @_ctx = ctx
      end

      # This is the entry-point for the action's execution.
      # rubocop:disable Metrics/MethodLength
      def run
        return if @_ctx.failure?

        _validate_required_params
        _import_context

        # Suppress `FailureError`s since they're used to just exit the action.
        begin
          # Instance eval to expose instance variables.
          instance_eval(&self.class.run_block)
        rescue Arq::FailureError
          nil
        end

        _export_variables

        # Only validate returns if context is successful
        _validate_required_returns if @_ctx.success?

        nil
      end
      # rubocop:enable Metrics/MethodLength

      # Used to call another action using the current action's context.
      # Because of this, the context is exported and then imported again.
      def call_other(action)
        _export_variables
        action.call(@_ctx)
        _import_context
      end

      # Fails the context without exiting the current action.
      def fail!(message = nil)
        @_ctx.fail!(message)
      end

      # Fails the context and exits the current action.
      def fail_now!(message = nil)
        @_ctx.fail_now!(message)
      end

      # Used to easily call other actions via snake-cased modules and dot accessors.
      # IE `Foo::Bar::Action` can be called via `foo.bar.action`
      def method_missing(method, *args, &block)
        obj = Object.const_get(method.to_s.camelize)
        case obj
        when Arq::Action
          self.call_other(obj)
        when Module
          Arq::ModuleHash.new(obj, self)
        end
      rescue NameError => _e
        super
      end

      def respond_to_missing?(method, include_private: false)
        Object.const_defined?(method.to_s.camelize) || super
      end

      private

      # Load parameters of context as instance variables
      def _import_context
        @_ctx.each do |key, val|
          instance_variable_set(:"@#{key}", val)
        end
      end

      # Exports instance variables (excluding those prefixed with _) to the context
      def _export_variables
        # Filter out vars starting with _
        vars = instance_variables.filter do |key|
          !key.start_with?("@_")
        end

        vars.each do |var|
          # Strip @ prefix
          key = var[1..].to_sym

          @_ctx[key] = instance_variable_get(var)
        end
      end

      def _validate_required_params
        missing_params = (self.class.params_list - @_ctx.keys)
        raise Arq::ParametersNotInContextError, missing_params unless missing_params.empty?
      end

      def _validate_required_returns
        missing_returns = (self.class.returns_list - @_ctx.keys)
        raise Arq::ReturnValuesNotInContextError, missing_returns unless missing_returns.empty?
      end
    end
  end
end

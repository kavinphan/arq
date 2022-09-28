# frozen_string_literal: true

module Arq
  # Module to extend to create an action.
  module Action
    def self.extended(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    def self.included(base)
      raise "`Arq::Action` should be `extended`"
    end

    module ClassMethods
      # Runs the stored block with variables from the provided context.
      def call(ctx = Arq::Context.new)
        ctx = transform_input_context(ctx)

        inst = self.new(ctx)
        inst.call

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

    module InstanceMethods
      def initialize(ctx)
        @_ctx = ctx
      end

      def call
        return if @_ctx.failure?
  
        _validate_required_params
  
        val = _run
  
        # Only validate returns if context is successful
        _validate_required_returns if @_ctx.success?
  
        val
      end

      def fail!(message = nil)
        @_ctx.fail!(message)
      end
  
      def fail_now!(message = nil)
        @_ctx.fail_now!(message)
      end

      private

      def _run
        _import_context
        val = instance_eval(&self.class.run_block)
        _export_variables

        val
      rescue Arq::FailureError
        nil
      end

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

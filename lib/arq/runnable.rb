# frozen_string_literal: true

module Arq
  # Represents a process to run with a given context, parameters, and returns.
  # A Runnable is generated from an Action.
  class Runnable
    def initialize(ctx, params = [], returns = [], &block)
      @ctx     = ctx
      @params  = params
      @returns = returns
      @block   = block
    end

    def call
      return if @ctx.failure?

      validate_required_params

      import_context
      val = run_block
      export_context

      # If the block returned an array, attempt to run
      run_sequence(val) if val.is_a?(Array)

      # Only validate returns if context is successful
      validate_required_returns if @ctx.success?

      val
    end

    def run(&block)
      Arq::Runnable.new(@ctx, [], [], &block)
    end

    def fail!(message)
      @ctx.fail!(message)
    end

    def fail_now!(message)
      @ctx.fail_now!(message)
    end

    private

    def run_block
      instance_eval(&@block)
    rescue Arq::FailureError
      nil
    end

    def run_sequence(sequence)
      sequence.each do |e|
        case e
        when Arq::Action
          e.call(@ctx)
        when Arq::Runnable
          e.call
        end
      end
    end

    def import_context
      @ctx.each do |key, val|
        instance_variable_set(:"@#{key}", val)
      end
    end

    def export_context
      keys = [*@ctx.keys, *@returns]

      keys.each do |key|
        instance_key = :"@#{key}"
        # Must check for existence since getting non-existent
        # instance variables will return nil.
        @ctx[key] = instance_variable_get(instance_key) if instance_variables.include?(instance_key)
      end
    end

    def validate_required_params
      missing_params = (@params - @ctx.keys)
      raise Arq::ParametersNotInContextError, missing_params unless missing_params.empty?
    end

    def validate_required_returns
      missing_returns = (@returns - @ctx.keys)
      raise Arq::ReturnValuesNotInContextError, missing_returns unless missing_returns.empty?
    end
  end
end

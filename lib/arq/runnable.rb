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

      val = run_block

      # If the block returned an array, attempt to run
      run_sequence(val) if val.is_a?(Array)

      # Only validate returns if context is successful
      validate_required_returns if @ctx.success?

      val
    end

    def run(&block)
      Arq::Runnable.new(@ctx, [], [], &block)
    end

    def fail!(message = nil)
      @ctx.fail!(message)
    end

    def fail_now!(message = nil)
      @ctx.fail_now!(message)
    end

    private

    def run_block
      with_context do
        instance_eval(&@block)
      rescue Arq::FailureError
        nil
      end
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

    # Runs the block with context parameters set as instance variables, then
    # imports all context parameters and any new instance vars into the context.
    # Returns the return value of the block.
    def with_context
      # Grab all current variables to know what is being returned
      before_vars = instance_variables

      # Load all context parameters into runnable instance
      import_context_to_vars

      # Run block
      val = yield

      # Grab all ctx + new vars
      ctx_vars = instance_variables - before_vars

      # Import instance vars into ctx
      import_vars_to_context(ctx_vars)

      # Return block value
      val
    end

    def import_context_to_vars
      @ctx.each do |key, val|
        instance_variable_set(:"@#{key}", val)
      end
    end

    def import_vars_to_context(vars)
      vars.each do |var|
        key = var[1..].to_sym
        @ctx[key] = instance_variable_get(var)
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

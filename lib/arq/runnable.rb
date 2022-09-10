# frozen_string_literal: true

module Arq
  # Represents a process to run with a given context, parameters, and returns.
  # A Runnable is generated from an Action.
  class Runnable
    def initialize(ctx, params = [], returns = [], &block)
      @_ctx     = ctx
      @_params  = params
      @_returns = returns
      @_block   = block
    end

    def call
      return if @_ctx.failure?

      validate_required_params

      val = run_block

      # If the block returned an array, attempt to run
      run_sequence(val) if val.is_a?(Array)

      # Only validate returns if context is successful
      validate_required_returns if @_ctx.success?

      val
    end

    def run(&block)
      Arq::Runnable.new(@_ctx, [], [], &block)
    end

    def fail!(message = nil)
      @_ctx.fail!(message)
    end

    def fail_now!(message = nil)
      @_ctx.fail_now!(message)
    end

    private

    def run_block
      with_context do
        instance_eval(&@_block)
      rescue Arq::FailureError
        nil
      end
    end

    def run_sequence(sequence)
      sequence.each do |e|
        case e
        when Arq::Action
          e.call(@_ctx)
        when Arq::Runnable
          e.call
        end
      end
    end

    # Runs the block with context parameters set as instance variables, then
    # imports all context parameters and any new instance vars into the context.
    # Returns the return value of the block.
    def with_context
      import_context

      # Run block
      val = yield

      export_variables

      # Return block value
      val
    end

    # Load parameters of context as instance variables
    def import_context
      @_ctx.each do |key, val|
        instance_variable_set(:"@#{key}", val)
      end
    end

    # Exports instance variables (excluding those prefixed with _) to the context
    def export_variables
      # Filter out vars starting with _
      vars = instance_variables.filter do |key|
        !key.start_with?("@_")
      end

      vars.each do |var|
        key = var[1..].to_sym
        @_ctx[key] = instance_variable_get(var)
      end
    end

    def validate_required_params
      missing_params = (@_params - @_ctx.keys)
      raise Arq::ParametersNotInContextError, missing_params unless missing_params.empty?
    end

    def validate_required_returns
      missing_returns = (@_returns - @_ctx.keys)
      raise Arq::ReturnValuesNotInContextError, missing_returns unless missing_returns.empty?
    end
  end
end

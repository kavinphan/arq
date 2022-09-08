# frozen_string_literal: true

module Arq
  # Module to extend to create an action. Exposes confing functions #call, #params, and #returns.
  module Action
    def call(ctx = Arq::Context.new)
      ctx = transform_input_context(ctx)

      generate_runnable(ctx).call

      ctx
    end

    def params(*keys)
      params_list.concat(keys).compact
    end

    def returns(*keys)
      returns_list.concat(keys).compact
    end

    def run(&block)
      @run_block = block
    end

    private

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

    def generate_runnable(ctx)
      Arq::Runnable.new(ctx, params_list, returns_list, &run_block)
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
  end
end

# frozen_string_literal: true

module Arq
  # Raised when the context for an action is not a Arq::Context or a Hash.
  class InvalidContextParameterError < StandardError
    def initialize
      super("Must be a Arq::Context or Hash")
    end
  end

  # Raised when action parameters do not exist within the passed context.
  class ParametersNotInContextError < StandardError
    def initialize(params)
      super(params.join(", "))
    end
  end

  # Raised when action return keys do not exist within the passed context.
  class ReturnValuesNotInContextError < StandardError
    def initialize(returns)
      super(returns.join(", "))
    end
  end

  # Raised internally in [Arq::Runnable#fail!] to escape the current action.
  # FailureError extends from Exception to avoid being rescued as a StandardError.
  # rubocop:disable Lint/InheritException
  class FailureError < Exception
  end
  # rubocop:enable Lint/InheritException
end

# frozen_string_literal: true

module Arq
  # Light wrapper around Hash with additional properties for action results.
  class Context < Hash
    def initialize(params = {})
      super(nil)
      merge!(params)
    end

    def fail!(message = nil)
      @failure = true
      @message = message
    end

    def fail_now!(message = nil)
      fail!(message)
      raise Arq::FailureError
    end

    def failure?
      @failure ||= false
    end

    def success?
      !failure?
    end

    def message
      @message ||= ""
    end
  end
end

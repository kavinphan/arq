# frozen_string_literal: true

# Verifies that:
#   - Instance variables are exported to the context even when the action is failed

require "spec_helper"
require "arq"

class Failure
  extend Arq::Action

  returns :out

  run do
    @out = "arq"

    fail_now!
  end
end

describe Failure do
  let(:ctx) { Arq::Context.new }

  it "sets the `out` parameter in context" do
    expect do
      described_class.call(ctx)
    end.to change { ctx[:out] }.from(nil).to("arq")
  end
end

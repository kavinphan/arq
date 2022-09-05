# frozen_string_literal: true

require "spec_helper"
require "arq"

class Echo
  extend Arq::Action

  params  :ping
  returns :pong

  run do
    @pong = @ping
  end
end

describe Echo do
  let(:ping) { "hello world" }

  let(:ctx) do
    Arq::Context.new(ping: ping)
  end

  context "when `ping` param is not in context" do
    let(:ctx) do
      Arq::Context.new
    end

    it "raises ParametersNotInContextError" do
      expect do
        described_class.call(ctx)
      end.to raise_error(Arq::ParametersNotInContextError)
    end
  end

  context "when `ping` param is in context" do
    it "sets the `pong` param with the value of the `ping` param" do
      expect do
        described_class.call(ctx)
      end.to change { ctx[:pong] }.from(nil).to(ping)
    end

    it "returns the context" do
      expect(described_class.call(ctx)).to eq(ctx)
    end
  end
end

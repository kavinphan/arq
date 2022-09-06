# frozen_string_literal: true

require "spec_helper"
require "arq"

class ReturnTest
  extend Arq::Action

  params  :set_out
  returns :out

  run do
    @out = "value" if @set_out
  end
end

describe ReturnTest do
  let(:set_out) { true }

  let(:ctx) do
    Arq::Context.new(set_out: set_out)
  end

  context "when `set_out` param is not in context" do
    let(:ctx) do
      Arq::Context.new
    end

    it "raises ParametersNotInContextError" do
      expect do
        described_class.call(ctx)
      end.to raise_error(Arq::ParametersNotInContextError)
    end
  end

  context "when `set_out` param is in context" do
    context "when `set_out` param is false" do
      let(:set_out) { false }

      it "raises ReturnValuesNotInContextError" do
        expect do
          described_class.call(ctx)
        end.to raise_error(Arq::ReturnValuesNotInContextError)
      end
    end

    context "when `set_out` param is true" do
      it "sets the `out` param" do
        expect do
          described_class.call(ctx)
        end.to change { ctx[:out] }.from(nil)
      end

      it "returns the context" do
        expect(described_class.call(ctx)).to eq(ctx)
      end
    end
  end
end

# frozen_string_literal: true

class SpellFoo
  extend Arq::Action

  params :string, :o_count

  run do
    # Can't spell foo with less than 2 Os
    fail_now!("o_count must be >=2") if @o_count < 2

    [
      AddF,
      *Array.new(@o_count) { AddO }
    ]
  end
end

class AddF
  extend Arq::Action

  params :string

  run do
    @string += "f"
  end
end

class AddO
  extend Arq::Action

  params :string

  run do
    @string += "o"
  end
end

describe SpellFoo do
  # This value is used to see if the `string` param was changed
  let(:base_string) { "lorem ipsum " }

  let(:string)  { base_string }
  let(:o_count) { 2 }

  let(:ctx) do
    Arq::Context.new(string: string, o_count: o_count)
  end

  before do
    allow(AddF).to receive(:call).and_call_original
    allow(AddO).to receive(:call).and_call_original
  end

  context "when the `string` param is not in context" do
    let(:ctx) do
      Arq::Context.new(o_count: o_count)
    end

    it "raises ParametersNotInContextError" do
      expect do
        described_class.call(ctx)
      end.to raise_error(Arq::ParametersNotInContextError)
    end
  end

  context "when the `o_count` param is not in context" do
    let(:ctx) do
      Arq::Context.new(string: string)
    end

    it "raises ParametersNotInContextError" do
      expect do
        described_class.call(ctx)
      end.to raise_error(Arq::ParametersNotInContextError)
    end
  end

  context "when `o_count` is less than 2" do
    let(:o_count) { 1 }

    it "fails the context" do
      expect do
        described_class.call(ctx)
      end.to change(ctx, :failure?).from(false).to(true)
    end

    it "returns the context" do
      expect(described_class.call(ctx)).to eq(ctx)
    end
  end

  context "when `o_count` is greater than or equal to 2" do
    let(:o_count) { 42 }

    it "calls AddF once" do
      described_class.call(ctx)

      expect(AddF).to have_received(:call).once
    end

    it "calls AddO `o_count` times" do
      described_class.call(ctx)

      expect(AddO).to have_received(:call).exactly(o_count).times
    end

    it "changes the value in context to the expected value" do
      expected = "#{base_string}f#{"o" * o_count}"

      expect do
        described_class.call(ctx)
      end.to change { ctx[:string] }.from(base_string).to(expected)
    end

    it "returns the context" do
      expect(described_class.call(ctx)).to eq(ctx)
    end
  end
end

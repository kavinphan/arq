# frozen_string_literal: true

# Verifies that:
#   - Anonymous run blocks can access and mutate context parameters

class AnonRun
  extend Arq::Action

  params  :name
  returns :greeting

  run do
    [
      run do
        @greeting = ["hello", @name]
      end,
      run do
        @greeting = @greeting.join(" ")
      end
    ]
  end
end

describe AnonRun do
  let(:name) { Faker::Name.first_name }

  let(:ctx) do
    Arq::Context.new(name: name)
  end

  it "sets the `greeting` param in context" do
    expect do
      described_class.call(ctx)
    end.to change { ctx[:greeting] }.from(nil).to("hello #{name}")
  end
end

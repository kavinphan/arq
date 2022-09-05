# Arq

**Arq** is a service skeleton framework heavily inspired by [LightService](https://github.com/adomokos/light-service) with the primary goal of being **less verbose**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'arq'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install arq
```

## Usage

### Actions

Actions are the building blocks of arq. Each action has a strict set of parameters and return values that must exist when the action is run and ended, respectfully. They can be [run directly](#running-an-action) or [used in other actions](#chaining-actions).

Actions are run with a given `Arq::Context` (a light wrapper around `Hash`) whose values are exposed via instance variables and are used as the parameters. Return values are set via instance variables as well.

### Creating Actions

Actions can be created by extending `Arq::Action` and configured using the functions `params`, `returns`, and `run`.

```ruby
class Echo
  extend Arq::Action

  params  :ping
  returns :pong

  run do
    @pong = @ping
  end
end
```

### Running Actions

Actions are run via the `#call` method. `#call` accepts either a `Arq::Context` or `Hash` (which is immediately wrapped in a `Arq::Context`) and returns the resulting `Arq::Context`.

```ruby
result = EchoAction.call(ping: "hello world!")
result[:pong] # => "hello world!"
```

If the given `Hash` or `Arq::Context` does not contain all of the parameters defined by the action, `Arq::ParametersNotInContextError` is raised.

```ruby
Echo.call(something_else: 2)
# Arq::ParametersNotInContextError: Missing parameters: ping
```

Likewise if the resulting context does not contain the return values defined by the action, `Arq::ReturnValuesNotInContextError` is raised.

### Chaining Actions

Actions can return a sequence of other actions to run.

```ruby
class SpellFoo
  extend Arq::Action

  params  :string, :o_count

  run do
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

result = SpellFoo.call(string: "spelling time: ", o_count: 5)
result[:string] # => "spelling time: fooooo"
```

### Failing

Calling either `#fail!` or `#fail_now!` will cause the context to enter a failure state, with the latter preventing further processing of the current action. Running `#call` with a failed context will immediately return.

Note that return values are not validated when the context is failed.

**`#fail!`**

```ruby
class FailTest
  extend Arq::Action

  params  :in
  returns :out

  run do
    if @in == 0
      fail! "@in is 0"
    end

    @out = 1
  end
end

result = FailTest.call(in: 0)
result.failure? # => true
result[:out]    # => 1
```

**`#fail_now!`**

```ruby
class FailTest
  extend Arq::Action

  params  :in
  returns :out

  run do
    if @in == 0
      fail_now! "@in is 0"
    end

    @out = 1
  end
end

result = FailTest.call(in: 0)
result.failure? # => true
result[:out]    # => nil
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kphan32/arq. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kphan32/arq/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Arq project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kphan32/arq/blob/main/CODE_OF_CONDUCT.md).

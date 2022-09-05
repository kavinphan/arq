# frozen_string_literal: true

require_relative "lib/arq/version"

Gem::Specification.new do |spec|
  spec.name = "arq"
  spec.version = Arq::VERSION
  spec.authors = ["Kavin Phan"]
  spec.email = ["kavin@kphan.tech"]

  spec.summary     = "A simple service skeleton framework"
  spec.description = "A service skeleton framework heavily inspired by LightService with the primary goal of being less verbose."
  spec.homepage = "https://github.com/kphan32/arq"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.3"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/kphan32/arq/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/github/kphan32/arq/main"

  spec.files = Dir["lib/**/*.rb"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end

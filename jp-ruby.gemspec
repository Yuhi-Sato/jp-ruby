# frozen_string_literal: true

require_relative "lib/jp_ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "jp-ruby"
  spec.version       = JpRuby::VERSION
  spec.authors       = ["jp-ruby contributors"]
  spec.email         = []
  spec.summary       = "日本語でRubyを書こう - Write Ruby in Japanese"
  spec.description   = "A preprocessor that allows writing Ruby code using Japanese keywords. " \
                        "Reads .jrb files, transpiles Japanese keywords to Ruby, and executes them."
  spec.homepage      = "https://github.com/jp-ruby/jp-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files         = Dir["lib/**/*.rb", "exe/*", "LICENSE.txt"]
  spec.bindir        = "exe"
  spec.executables   = ["jp-ruby"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.12"
end

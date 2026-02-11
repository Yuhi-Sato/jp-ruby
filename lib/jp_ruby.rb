# frozen_string_literal: true

require_relative "jp_ruby/version"
require_relative "jp_ruby/errors"
require_relative "jp_ruby/keywords"
require_relative "jp_ruby/tokenizer"
require_relative "jp_ruby/transpiler"
require_relative "jp_ruby/runtime"
require_relative "jp_ruby/config"
require_relative "jp_ruby/runner"

module JpRuby
  def self.transpile(source, filename: "(jp-ruby)", **options)
    Transpiler.new(source, filename: filename, **options).transpile
  end

  def self.run(filename, **options)
    Runner.new(filename, options).run
  end
end

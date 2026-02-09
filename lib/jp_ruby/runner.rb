# frozen_string_literal: true

module JpRuby
  class Runner
    def initialize(filename, options = {})
      @filename = filename
      @options = options
    end

    def run
      source = File.read(@filename, encoding: "UTF-8")
      transpiler = Transpiler.new(source, filename: @filename)
      ruby_code = transpiler.transpile

      if @options[:dump]
        $stdout.puts ruby_code
        return
      end

      Runtime.load!

      # Execute with original filename for error reporting
      # Line numbers are preserved because keyword replacement doesn't change line structure
      eval(ruby_code, TOPLEVEL_BINDING, @filename, 1) # rubocop:disable Security/Eval
    rescue SyntaxError => e
      raise JpRuby::TranspileError.new(
        "構文エラー: #{e.message}",
        filename: @filename,
        original_error: e
      )
    end
  end
end

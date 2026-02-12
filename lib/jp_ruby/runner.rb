# frozen_string_literal: true

module JpRuby
  class Runner
    def initialize(filename, options = {})
      @filename = filename
      @options = options
    end

    def run
      # Discover and load config
      config_path = Config.discover(
        input_file: @filename,
        explicit_path: @options[:config]
      )
      config = Config.new(config_path)

      keyword_map = config.build_keyword_map
      class_declaration_keywords = config.build_class_declaration_keywords(keyword_map)

      source = File.read(@filename, encoding: "UTF-8")
      transpiler = Transpiler.new(source, filename: @filename,
                                  keyword_map: keyword_map,
                                  class_declaration_keywords: class_declaration_keywords)
      ruby_code = transpiler.transpile

      if @options[:dump]
        $stdout.puts ruby_code
        return
      end

      # Load runtime with custom aliases
      Runtime.load!(config.build_runtime_map)

      # Execute with original filename for error reporting
      # Line numbers are preserved because keyword replacement doesn't change line structure
      eval(ruby_code, TOPLEVEL_BINDING, @filename, 1) # rubocop:disable Security/Eval
    rescue SyntaxError => e
      localized_message = ErrorLocalizer.localize(
        e.message,
        keyword_map: keyword_map,
        class_names: transpiler&.class_names || []
      )
      raise JpRuby::TranspileError.new(
        "構文エラー: #{localized_message}",
        filename: @filename,
        original_error: e
      )
    end
  end
end

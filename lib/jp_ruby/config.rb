# frozen_string_literal: true

require "yaml"

module JpRuby
  class Config
    RESERVED_SECTIONS = %w[Keyword].freeze

    attr_reader :keyword_overrides, :runtime_overrides

    def initialize(config_path = nil)
      @keyword_overrides = {}
      @runtime_overrides = {}
      load_config(config_path) if config_path
    end

    # Find config file using the discovery chain
    def self.discover(input_file: nil, explicit_path: nil)
      if explicit_path
        unless File.exist?(explicit_path)
          raise JpRuby::ConfigError, "設定ファイルが見つかりません: #{explicit_path}"
        end

        return explicit_path
      end

      candidates = []
      candidates << File.join(File.dirname(File.expand_path(input_file)), ".jp-ruby.yml") if input_file
      candidates << File.join(Dir.pwd, ".jp-ruby.yml")
      candidates << File.join(Dir.home, ".jp-ruby.yml")

      candidates.find { |path| File.exist?(path) }
    end

    # Build a merged KEYWORD_MAP (default + overrides, override mode)
    def build_keyword_map
      base = Keywords::DEFAULT_KEYWORD_MAP.dup

      @keyword_overrides.each do |english, new_japanese|
        # Remove the old Japanese key that maps to this English keyword
        old_japanese = base.key(english)
        base.delete(old_japanese) if old_japanese

        # Check if the new Japanese word conflicts with an existing entry
        if base.key?(new_japanese) && base[new_japanese] != english
          raise ConfigError, "日本語キーワード '#{new_japanese}' が複数の英語キーワードにマッピングされています: " \
                             "'#{base[new_japanese]}' と '#{english}'"
        end

        # Add new mapping
        base[new_japanese] = english
      end

      base.to_h.freeze
    end

    # Build CLASS_DECLARATION_KEYWORDS based on current keyword map
    def build_class_declaration_keywords(keyword_map)
      %w[class module].filter_map { |eng| keyword_map.key(eng) }.freeze
    end

    # Build runtime alias map with overrides applied
    def build_runtime_map
      base = deep_copy_runtime_defaults

      @runtime_overrides.each do |class_name, methods|
        base[class_name] ||= {}
        methods.each do |english_method, new_japanese|
          # Remove old Japanese alias for this English method if it exists
          old_japanese = base[class_name].key(english_method)
          base[class_name].delete(old_japanese) if old_japanese
          # Add new alias
          base[class_name][new_japanese] = english_method
        end
      end

      base
    end

    private

    def load_config(path)
      raw = YAML.safe_load(File.read(path, encoding: "UTF-8"))
      return if raw.nil? || raw == false

      unless raw.is_a?(Hash)
        raise JpRuby::ConfigError, "設定ファイルの形式が正しくありません: #{path}"
      end

      validate_and_extract(raw, path)
    rescue Psych::SyntaxError => e
      raise JpRuby::ConfigError, "YAML構文エラー (#{path}): #{e.message}"
    end

    def validate_and_extract(raw, path)
      raw.each do |section, entries|
        unless entries.is_a?(Hash)
          raise JpRuby::ConfigError,
                "セクション '#{section}' はハッシュである必要があります (#{path})"
        end

        if section == "Keyword"
          validate_keyword_section(entries, path)
          @keyword_overrides = entries
        else
          resolve_class(section, path)
          validate_runtime_section(section, entries, path)
          @runtime_overrides[section] = entries
        end
      end
    end

    def validate_keyword_section(entries, path)
      entries.each do |english, japanese|
        unless english.is_a?(String) && japanese.is_a?(String)
          raise JpRuby::ConfigError,
                "Keywordセクションのキーと値は文字列である必要があります (#{path})"
        end

        if japanese.strip.empty?
          raise JpRuby::ConfigError,
                "空のキーワードは許可されていません: '#{english}' (#{path})"
        end
      end
    end

    def validate_runtime_section(class_name, entries, path)
      entries.each do |english_method, japanese_alias|
        unless english_method.is_a?(String) && japanese_alias.is_a?(String)
          raise JpRuby::ConfigError,
                "#{class_name}セクションのキーと値は文字列である必要があります (#{path})"
        end

        if japanese_alias.strip.empty?
          raise JpRuby::ConfigError,
                "空のエイリアスは許可されていません: #{class_name}##{english_method} (#{path})"
        end
      end
    end

    def resolve_class(class_name, path)
      Object.const_get(class_name)
    rescue NameError
      raise JpRuby::ConfigError,
            "不明なクラス '#{class_name}' (#{path}). Rubyに存在するクラス名を指定してください"
    end

    def deep_copy_runtime_defaults
      Runtime::DEFAULT_ALIASES.transform_values(&:dup)
    end
  end
end

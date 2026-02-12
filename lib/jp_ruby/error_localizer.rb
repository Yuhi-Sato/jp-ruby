# frozen_string_literal: true

module JpRuby
  module ErrorLocalizer
    # Reverse-maps English keywords and class name C-prefixes back to Japanese
    # in a SyntaxError message.
    def self.localize(message, keyword_map:, class_names: [])
      reverse_map = build_reverse_map(keyword_map)
      result = message.dup

      # Phase 1: Reverse class name C-prefix (C犬 -> 犬)
      class_names.each do |name|
        result.gsub!(/\bC#{Regexp.escape(name)}\b/, name)
      end

      # Phase 2: Reverse keywords in code snippet lines (e.g. "  1 | def" -> "  1 | 定義")
      result = result.gsub(/^(\s*>?\s*\d+\s*\|)(.*)$/) do
        prefix = ::Regexp.last_match(1)
        code_part = ::Regexp.last_match(2)
        prefix + reverse_keywords(code_part, reverse_map)
      end

      # Phase 3: Reverse keywords in backtick-quoted references (e.g. `end` -> `終わり`)
      result = result.gsub(/`([^`]+)`/) do
        inner = ::Regexp.last_match(1)
        "`#{reverse_map.fetch(inner, inner)}`"
      end

      result
    end

    def self.build_reverse_map(keyword_map)
      keyword_map.each_with_object({}) do |(japanese, english), hash|
        hash[english] = japanese
      end
    end

    def self.reverse_keywords(code, reverse_map)
      sorted_keys = reverse_map.keys.sort_by { |k| -k.length }
      pattern = Regexp.union(sorted_keys.map { |k| /\b#{Regexp.escape(k)}\b/ })
      code.gsub(pattern) { |match| reverse_map[match] }
    end

    private_class_method :build_reverse_map, :reverse_keywords
  end
end

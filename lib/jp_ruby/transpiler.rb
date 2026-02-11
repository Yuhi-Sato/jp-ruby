# frozen_string_literal: true

module JpRuby
  class Transpiler
    def initialize(source, filename: "(jp-ruby)",
                   keyword_map: Keywords::DEFAULT_KEYWORD_MAP,
                   class_declaration_keywords: Keywords::DEFAULT_CLASS_DECLARATION_KEYWORDS)
      @source = source
      @filename = filename
      @keyword_map = keyword_map
      @class_declaration_keywords = class_declaration_keywords
    end

    def transpile
      tokens = Tokenizer.new(@source).tokenize
      class_names = collect_class_names(tokens)

      tokens.map do |token|
        if token.type == :word
          replace_word(token.value, class_names)
        else
          token.value
        end
      end.join
    end

    private

    def collect_class_names(tokens)
      class_names = []
      i = 0
      while i < tokens.length
        if tokens[i].type == :word && @class_declaration_keywords.include?(tokens[i].value)
          # Skip spaces, find the next word token
          j = i + 1
          j += 1 while j < tokens.length && tokens[j].type == :space
          if j < tokens.length && tokens[j].type == :word
            name = tokens[j].value
            # Only add if it wouldn't be a valid Ruby constant (doesn't start with A-Z)
            class_names << name unless name.match?(/\A[A-Z]/)
          end
        end
        i += 1
      end
      class_names.uniq
    end

    def replace_word(word, class_names)
      # Check if this word is a collected class/module name
      if class_names.include?(word)
        return "C#{word}"
      end

      # Check if this word matches a keyword
      if (english = @keyword_map[word])
        return english
      end

      # Not a keyword or class name -- return as-is
      word
    end
  end
end

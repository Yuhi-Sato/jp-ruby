# frozen_string_literal: true

module JpRuby
  class Transpiler
    def initialize(source, filename: "(jp-ruby)")
      @source = source
      @filename = filename
    end

    def transpile
      tokens = Tokenizer.new(@source).tokenize
      class_names = collect_class_names(tokens)
      class_names.sort_by! { |n| -n.length }

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
        if tokens[i].type == :word && Keywords::CLASS_DECLARATION_KEYWORDS.include?(tokens[i].value)
          # Skip spaces, find the next word token
          j = i + 1
          j += 1 while j < tokens.length && tokens[j].type == :space
          if j < tokens.length && tokens[j].type == :word
            name = tokens[j].value
            # Only add if it starts with a non-ASCII character (Japanese)
            class_names << name if name.match?(/\A[^\x00-\x7F]/)
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
      if (english = Keywords::KEYWORD_MAP[word])
        return english
      end

      # Not a keyword or class name -- return as-is
      word
    end
  end
end

# frozen_string_literal: true

require "strscan"

module JpRuby
  Token = Struct.new(:type, :value, keyword_init: true)

  class Tokenizer
    # Matches Unicode letters (including Japanese), digits, underscores
    WORD_PATTERN = /[\p{L}_][\p{L}\p{N}_]*[?!]?/

    def initialize(source)
      @scanner = StringScanner.new(source)
      @tokens = []
      @state_stack = [:code]
      @pending_heredocs = []
      @line_start = true
    end

    def tokenize
      until @scanner.eos?
        case current_state
        when :code
          scan_code
        when :double_string
          scan_double_string
        when :single_string
          scan_single_string
        when :comment
          scan_comment
        when :multi_comment
          scan_multi_comment
        when :regex
          scan_regex
        when :heredoc
          scan_heredoc
        when :interpolation
          scan_interpolation
        when :percent_literal
          scan_percent_literal
        when :backtick
          scan_backtick
        end
      end

      @tokens
    end

    private

    def current_state
      @state_stack.last
    end

    def push_state(state)
      @state_stack.push(state)
    end

    def pop_state
      @state_stack.pop
    end

    def emit(type, value)
      @tokens << Token.new(type: type, value: value)
    end

    # --- CODE state ---

    def scan_code
      # Multi-line comment start (=begin at line start)
      if @line_start && @scanner.check(/=begin\b/)
        text = @scanner.scan(/=begin.*/)
        emit(:comment, text)
        push_state(:multi_comment)
        @line_start = false
        return
      end

      @line_start = false

      # Whitespace (including newlines)
      if (ws = @scanner.scan(/[ \t]+/))
        emit(:space, ws)
        return
      end

      # Newline
      if (nl = @scanner.scan(/\r?\n/))
        emit(:space, nl)
        @line_start = true
        check_pending_heredocs
        return
      end

      # Line comment
      if @scanner.check(/#/) && !@scanner.check(/#\{/)
        text = @scanner.scan(/#.*/)
        emit(:comment, text)
        return
      end

      # Heredoc
      if (heredoc = @scanner.scan(/<<[-~]?['"]?\w+['"]?/))
        parse_heredoc_start(heredoc)
        return
      end

      # Double-quoted string
      if @scanner.scan(/"/)
        emit(:other, '"')
        push_state(:double_string)
        return
      end

      # Single-quoted string
      if @scanner.scan(/'/)
        emit(:other, "'")
        push_state(:single_string)
        return
      end

      # Backtick string
      if @scanner.scan(/`/)
        emit(:other, "`")
        push_state(:backtick)
        return
      end

      # Percent literal
      if @scanner.check(/%[qQwWiIrx]?[{\[\(<]/)
        scan_percent_literal_start
        return
      end

      # Regex (heuristic: not after identifier, number, ), ], })
      if @scanner.check(%r{/}) && regex_possible?
        @scanner.scan(%r{/})
        emit(:other, "/")
        push_state(:regex)
        return
      end

      # Symbol with string
      if @scanner.scan(/:"/)
        emit(:other, ':"')
        push_state(:double_string)
        return
      end

      if @scanner.scan(/:'/)
        emit(:other, ":'")
        push_state(:single_string)
        return
      end

      # Word (identifier or keyword)
      if (word = @scanner.scan(WORD_PATTERN))
        emit(:word, word)
        return
      end

      # Any other character (operators, numbers, punctuation, etc.)
      if (ch = @scanner.scan(/./m))
        emit(:other, ch)
      end
    end

    # --- DOUBLE STRING state ---

    def scan_double_string
      if @scanner.scan(/\\./m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#\{/)
        emit(:interp_begin, '#{')
        push_state(:interpolation)
      elsif @scanner.scan(/"/)
        emit(:other, '"')
        pop_state
      elsif @scanner.scan(/[^"\\#]+/m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#/)
        emit(:string_part, "#")
      end
    end

    # --- SINGLE STRING state ---

    def scan_single_string
      if @scanner.scan(/\\[\\']/)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/'/)
        emit(:other, "'")
        pop_state
      elsif @scanner.scan(/[^'\\]+/m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/\\/)
        emit(:string_part, "\\")
      end
    end

    # --- COMMENT state ---

    def scan_comment
      if (text = @scanner.scan(/.*$/))
        emit(:comment, text)
        pop_state
      end
    end

    # --- MULTI COMMENT state (=begin ... =end) ---

    def scan_multi_comment
      if @scanner.scan(/\r?\n/)
        emit(:comment, @scanner.matched)
        @line_start = true

        if @scanner.check(/=end\b/)
          text = @scanner.scan(/=end.*/)
          emit(:comment, text)
          pop_state
          @line_start = false
        end
      elsif (text = @scanner.scan(/.+/))
        emit(:comment, text)
      end
    end

    # --- REGEX state ---

    def scan_regex
      if @scanner.scan(/\\./m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#\{/)
        emit(:interp_begin, '#{')
        push_state(:interpolation)
      elsif @scanner.scan(%r{/[imxouesn]*})
        emit(:other, @scanner.matched)
        pop_state
      elsif @scanner.scan(%r{[^/\\#]+}m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#/)
        emit(:string_part, "#")
      end
    end

    # --- INTERPOLATION state ---

    def scan_interpolation
      @brace_depth ||= 1

      if @scanner.scan(/\{/)
        @brace_depth += 1
        emit(:other, "{")
      elsif @scanner.scan(/\}/)
        @brace_depth -= 1
        if @brace_depth == 0
          emit(:interp_end, "}")
          pop_state
          @brace_depth = nil
        else
          emit(:other, "}")
        end
      else
        # Process as code within interpolation
        scan_code
      end
    end

    # --- HEREDOC ---

    def parse_heredoc_start(heredoc_token)
      emit(:other, heredoc_token)

      # Parse the delimiter
      if heredoc_token =~ /<<[-~]?'(\w+)'/
        @pending_heredocs << { delimiter: $1, interpolation: false }
      elsif heredoc_token =~ /<<[-~]?"?(\w+)"?/
        @pending_heredocs << { delimiter: $1, interpolation: true }
      end
    end

    def check_pending_heredocs
      return if @pending_heredocs.empty?

      heredoc = @pending_heredocs.first
      push_state(:heredoc)
      @current_heredoc = heredoc
    end

    def scan_heredoc
      heredoc = @current_heredoc
      delimiter = heredoc[:delimiter]

      # Check for end delimiter (possibly with leading whitespace)
      if @scanner.check(/\s*#{Regexp.escape(delimiter)}\s*$/) ||
         @scanner.check(/\s*#{Regexp.escape(delimiter)}\s*\r?\n/) ||
         @scanner.check(/\s*#{Regexp.escape(delimiter)}\z/)
        line = @scanner.scan(/\s*#{Regexp.escape(delimiter)}/)
        emit(:string_part, line)
        @pending_heredocs.shift
        @current_heredoc = nil
        pop_state
        @line_start = false
      elsif heredoc[:interpolation] && @scanner.check(/#\{/)
        @scanner.scan(/#\{/)
        emit(:interp_begin, '#{')
        push_state(:interpolation)
      elsif heredoc[:interpolation]
        if (text = @scanner.scan(/[^#\n]+/))
          emit(:string_part, text)
        elsif @scanner.scan(/#/)
          emit(:string_part, "#")
        elsif @scanner.scan(/\n/)
          emit(:string_part, "\n")
        end
      else
        # No interpolation - consume until newline
        if (text = @scanner.scan(/[^\n]*/))
          emit(:string_part, text)
        end
        if @scanner.scan(/\n/)
          emit(:string_part, "\n")
        end
      end
    end

    # --- PERCENT LITERAL ---

    def scan_percent_literal_start
      prefix = @scanner.scan(/%[qQwWiIrx]?/)
      opener = @scanner.scan(/[{\[\(<]/)

      emit(:other, prefix + opener)

      closer = { "{" => "}", "[" => "]", "(" => ")", "<" => ">" }[opener]
      has_interpolation = prefix.match?(/\A%[QWIrx]?\z/) && !prefix.match?(/\A%[qwi]\z/)

      @percent_literal_closer = closer
      @percent_literal_opener = opener
      @percent_literal_depth = 1
      @percent_literal_interpolation = has_interpolation

      push_state(:percent_literal)
    end

    def scan_percent_literal
      closer = @percent_literal_closer
      opener = @percent_literal_opener

      if @scanner.scan(/\\./m)
        emit(:string_part, @scanner.matched)
      elsif @percent_literal_interpolation && @scanner.scan(/#\{/)
        emit(:interp_begin, '#{')
        push_state(:interpolation)
      elsif @scanner.scan(Regexp.new(Regexp.escape(opener)))
        @percent_literal_depth += 1
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(Regexp.new(Regexp.escape(closer)))
        @percent_literal_depth -= 1
        if @percent_literal_depth == 0
          emit(:other, @scanner.matched)
          pop_state
        else
          emit(:string_part, @scanner.matched)
        end
      elsif @percent_literal_interpolation
        if (text = @scanner.scan(/[^\\#{Regexp.escape(opener)}#{Regexp.escape(closer)}#]+/m))
          emit(:string_part, text)
        elsif @scanner.scan(/#/)
          emit(:string_part, "#")
        end
      else
        pattern = /[^\\#{Regexp.escape(opener)}#{Regexp.escape(closer)}]+/m
        if (text = @scanner.scan(pattern))
          emit(:string_part, text)
        end
      end
    end

    # --- BACKTICK state ---

    def scan_backtick
      if @scanner.scan(/\\./m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#\{/)
        emit(:interp_begin, '#{')
        push_state(:interpolation)
      elsif @scanner.scan(/`/)
        emit(:other, "`")
        pop_state
      elsif @scanner.scan(/[^`\\#]+/m)
        emit(:string_part, @scanner.matched)
      elsif @scanner.scan(/#/)
        emit(:string_part, "#")
      end
    end

    # --- Helpers ---

    def regex_possible?
      # Regex is possible if the previous non-space token is not an identifier,
      # number, closing bracket, or similar
      prev = @tokens.reverse_each.find { |t| t.type != :space }
      return true if prev.nil?

      case prev.type
      when :word
        # After a keyword, regex is possible
        true
      when :other
        !prev.value.match?(/[\w\d)\]}>]$/)
      else
        true
      end
    end
  end
end

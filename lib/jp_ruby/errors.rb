# frozen_string_literal: true

module JpRuby
  class Error < StandardError; end

  class TranspileError < Error
    attr_reader :filename, :original_error

    def initialize(message, filename: nil, original_error: nil)
      @filename = filename
      @original_error = original_error
      super(message)
    end
  end

  class TokenizeError < Error
    attr_reader :line, :column

    def initialize(message, line: nil, column: nil)
      @line = line
      @column = column
      super(message)
    end
  end
end

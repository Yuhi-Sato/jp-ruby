# frozen_string_literal: true

require "ripper"

module JpRuby
  Token = Struct.new(:type, :value, keyword_init: true)

  class Tokenizer
    WORD_TYPES = %i[on_ident on_kw on_const].to_set.freeze
    STRING_TYPES = %i[on_tstring_content].to_set.freeze
    COMMENT_TYPES = %i[on_comment on_embdoc on_embdoc_beg on_embdoc_end].to_set.freeze
    INTERP_BEGIN_TYPES = %i[on_embexpr_beg].to_set.freeze
    INTERP_END_TYPES = %i[on_embexpr_end].to_set.freeze
    SPACE_TYPES = %i[on_sp on_nl on_ignored_nl on_words_sep].to_set.freeze

    def initialize(source)
      @source = source
    end

    def tokenize
      return [] if @source.empty?

      Ripper.lex(@source).map do |(_line, _col), type, value, _state|
        Token.new(type: map_type(type), value: value)
      end
    end

    private

    def map_type(type)
      if WORD_TYPES.include?(type)
        :word
      elsif STRING_TYPES.include?(type)
        :string_part
      elsif COMMENT_TYPES.include?(type)
        :comment
      elsif INTERP_BEGIN_TYPES.include?(type)
        :interp_begin
      elsif INTERP_END_TYPES.include?(type)
        :interp_end
      elsif SPACE_TYPES.include?(type)
        :space
      else
        :other
      end
    end
  end
end

# frozen_string_literal: true

module JpRuby
  module Keywords
    # Japanese to Ruby keyword mapping
    # Sorted by length (longest first) to prevent partial matches during replacement
    KEYWORD_MAP = {
      # 7+ chars
      "そうでなければ" => "elsif",
      "ブロック渡し?" => "block_given?",
      "__エンコード__" => "__ENCODING__",

      # 5-6 chars
      "でない限り" => "unless",
      "モジュール" => "module",
      "__ファイル__" => "__FILE__",
      "__行番号__" => "__LINE__",
      "でなければ" => "else",
      "やり直す" => "redo",
      "定義済み?" => "defined?",
      "繰り返す" => "while",
      "繰り返し" => "for",
      "取り込む" => "include",
      "ではない" => "not",
      "相対必要" => "require_relative",
      "読み属性" => "attr_reader",
      "書き属性" => "attr_writer",

      # 3-4 chars
      "クラス" => "class",
      "または" => "or",
      "ラクター" => "Ractor",
      "データ" => "Data",
      "終わり" => "end",
      "始まり" => "begin",
      "再試行" => "retry",

      # 2 chars
      "定義" => "def",
      "初期化" => "initialize",
      "もし" => "if",
      "場合" => "case",
      "条件" => "when",
      "そして" => "then",
      "する" => "do",
      "中の" => "in",
      "まで" => "until",

      # Literals
      "真" => "true",
      "偽" => "false",
      "無" => "nil",

      # References
      "自分" => "self",
      "親" => "super",

      # Flow control
      "戻す" => "return",
      "次へ" => "next",
      "中断" => "break",
      "譲る" => "yield",

      # Exception
      "救済" => "rescue",
      "確保" => "ensure",
      "発生" => "raise",

      # Module/Access
      "拡張" => "extend",
      "公開" => "public",
      "非公開" => "private",
      "保護" => "protected",
      "別名" => "alias",
      "未定義" => "undef",

      # Logical
      "かつ" => "and",

      # Load
      "必要" => "require",

      # Output (also defined as runtime aliases)
      "表示" => "puts",
      "出力" => "print",
      "検査" => "p",

      # Method names
      "新規" => "new",
      "属性" => "attr_accessor",

      # Block parameters
      "それ" => "it",
    }.sort_by { |k, _| -k.length }.to_h.freeze

    # Keywords that declare class/module names
    CLASS_DECLARATION_KEYWORDS = %w[クラス モジュール].freeze
  end
end

# frozen_string_literal: true

module JpRuby
  module Runtime
    # Default alias definitions: { "ClassName" => { "japanese" => "english", ... } }
    DEFAULT_ALIASES = {
      "Kernel" => {
        "表示" => "puts",
        "出力" => "print",
        "検査" => "p",
        "取得" => "gets",
      },
      "Array" => {
        "それぞれ" => "each",
        "変換" => "map",
        "選択" => "select",
        "除外" => "reject",
        "畳み込み" => "reduce",
        "並べ替え" => "sort",
        "逆順" => "reverse",
        "平坦化" => "flatten",
        "一意" => "uniq",
        "含む?" => "include?",
        "追加" => "push",
        "長さ" => "length",
        "大きさ" => "size",
        "最初" => "first",
        "最後" => "last",
        "空?" => "empty?",
        "結合" => "join",
        "個数" => "count",
      },
      "Hash" => {
        "それぞれ" => "each",
        "鍵一覧" => "keys",
        "値一覧" => "values",
        "長さ" => "length",
        "含む?" => "include?",
        "空?" => "empty?",
        "結合" => "merge",
        "削除" => "delete",
      },
      "String" => {
        "長さ" => "length",
        "大きさ" => "size",
        "分割" => "split",
        "含む?" => "include?",
        "置換" => "gsub",
        "大文字" => "upcase",
        "小文字" => "downcase",
        "除去" => "strip",
        "空?" => "empty?",
        "逆順" => "reverse",
        "文字列変換" => "to_s",
        "整数変換" => "to_i",
        "小数変換" => "to_f",
      },
      "Integer" => {
        "回" => "times",
        "偶数?" => "even?",
        "奇数?" => "odd?",
        "文字列変換" => "to_s",
        "小数変換" => "to_f",
        "まで上" => "upto",
        "まで下" => "downto",
        "絶対値" => "abs",
      },
      "Float" => {
        "整数変換" => "to_i",
        "文字列変換" => "to_s",
        "切り上げ" => "ceil",
        "切り捨て" => "floor",
        "四捨五入" => "round",
        "絶対値" => "abs",
      },
      "Object" => {
        "凍結" => "freeze",
        "凍結済み?" => "frozen?",
        "複製" => "dup",
        "は?" => "is_a?",
        "応答する?" => "respond_to?",
      },
    }.freeze

    # Class name string to Ruby class mapping
    CLASS_MAP = {
      "Kernel" => ::Kernel,
      "Array" => ::Array,
      "Hash" => ::Hash,
      "String" => ::String,
      "Integer" => ::Integer,
      "Float" => ::Float,
      "Object" => ::Object,
    }.freeze

    # Kernel uses module_eval, others use class_eval
    MODULE_EVAL_CLASSES = %w[Kernel].freeze

    def self.load!(alias_map = nil)
      alias_map ||= DEFAULT_ALIASES

      alias_map.each do |class_name, aliases|
        target = CLASS_MAP.fetch(class_name) { Object.const_get(class_name) }

        eval_method = target.is_a?(Module) && !target.is_a?(Class) ? :module_eval : :class_eval

        target.send(eval_method) do
          aliases.each do |japanese, english|
            alias_method japanese.to_sym, english.to_sym
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::ErrorLocalizer do
  let(:keyword_map) { JpRuby::Keywords::DEFAULT_KEYWORD_MAP }

  describe ".localize" do
    it "コードスニペット行のキーワードを日本語に復元する" do
      message = <<~MSG.chomp
        test.jrb:2: syntax errors found
          1 | def
        > 2 | end
      MSG
      result = described_class.localize(message, keyword_map: keyword_map)
      expect(result).to include("  1 | 定義")
      expect(result).to include("> 2 | 終わり")
    end

    it "バッククォート内のキーワードを日本語に復元する" do
      message = "    |    ^ expected an `end` to close the `def` statement"
      result = described_class.localize(message, keyword_map: keyword_map)
      expect(result).to include("`終わり`")
      expect(result).to include("`定義`")
    end

    it "クラス名のCプレフィックスを除去する" do
      message = "  1 | class C犬"
      result = described_class.localize(message, keyword_map: keyword_map, class_names: ["犬"])
      expect(result).to include("クラス 犬")
      expect(result).not_to include("C犬")
    end

    it "部分一致しないこと" do
      message = "  1 | endless = 1"
      result = described_class.localize(message, keyword_map: keyword_map)
      expect(result).to include("endless")
      expect(result).not_to include("終わりless")
    end

    it "完全なSyntaxErrorメッセージを正しく復元する" do
      message = <<~MSG.chomp
        test.jrb:3: syntax errors found
          1 | class C犬
          2 | def
        > 3 | end
            |    ^ expected an `end` to close the `class` statement
            |    ^ expected an `end` to close the `def` statement
      MSG
      result = described_class.localize(message, keyword_map: keyword_map, class_names: ["犬"])
      expect(result).to include("クラス 犬")
      expect(result).not_to include("C犬")
      expect(result).to include("| 定義")
      expect(result).to include("| 終わり")
      expect(result).to include("`終わり`")
      expect(result).to include("`クラス`")
      expect(result).to include("`定義`")
    end

    it "キーワードが含まれないメッセージはそのまま返す" do
      message = "test.jrb:1: some error without keywords"
      result = described_class.localize(message, keyword_map: keyword_map)
      expect(result).to eq(message)
    end

    it "空のclass_namesでも動作する" do
      message = "  1 | def\n> 2 | end"
      result = described_class.localize(message, keyword_map: keyword_map, class_names: [])
      expect(result).to include("定義")
      expect(result).to include("終わり")
    end

    it "カスタムキーワードマップに対応する" do
      custom_map = { "組" => "class", "メソッド定義" => "def", "以上" => "end" }
      message = "  1 | class\n  2 | def\n> 3 | end"
      result = described_class.localize(message, keyword_map: custom_map)
      expect(result).to include("組")
      expect(result).to include("メソッド定義")
      expect(result).to include("以上")
    end
  end
end

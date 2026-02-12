# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::Tokenizer do
  def tokenize(source)
    described_class.new(source).tokenize
  end

  def token_values(source)
    tokenize(source).map(&:value)
  end

  def word_tokens(source)
    tokenize(source).select { |t| t.type == :word }.map(&:value)
  end

  def string_parts(source)
    tokenize(source).select { |t| t.type == :string_part }.map(&:value)
  end

  def comment_parts(source)
    tokenize(source).select { |t| t.type == :comment }.map(&:value)
  end

  # ============================================================
  # 基本トークン化
  # ============================================================
  describe "基本トークン化" do
    it "日本語ワード" do
      expect(word_tokens("クラス 犬")).to eq(%w[クラス 犬])
    end

    it "英語ワード" do
      expect(word_tokens("class Dog")).to eq(%w[class Dog])
    end

    it "日本語と英語の混在" do
      expect(word_tokens("クラス Dog < 動物")).to eq(%w[クラス Dog 動物])
    end

    it "空白を保持" do
      expect(token_values("クラス  犬")).to eq(["クラス", "  ", "犬"])
    end

    it "タブを保持" do
      expect(token_values("クラス\t犬")).to eq(["クラス", "\t", "犬"])
    end

    it "演算子" do
      expect(token_values("a + b")).to eq(["a", " ", "+", " ", "b"])
    end

    it "?で終わるワード" do
      expect(word_tokens("空? 含む? 偶数?")).to eq(%w[空? 含む? 偶数?])
    end

    it "!で終わるワード" do
      expect(word_tokens("保存! 削除!")).to eq(%w[保存! 削除!])
    end

    it "インスタンス変数" do
      expect(token_values("@名前")).to eq(["@名前"])
    end

    it "グローバル変数" do
      expect(token_values("$変数")).to eq(["$変数"])
    end

    it "シンボル" do
      expect(token_values(":名前")).to eq([":", "名前"])
    end

    it "改行を保持" do
      expect(token_values("a\nb").join).to eq("a\nb")
    end

    it "空の入力" do
      expect(tokenize("")).to eq([])
    end

    it "丸括弧" do
      expect(token_values("メソッド(引数)")).to eq(["メソッド", "(", "引数", ")"])
    end

    it "ドット(メソッド呼び出し)" do
      expect(token_values("オブジェクト.メソッド")).to eq(["オブジェクト", ".", "メソッド"])
    end

    it "パイプ(ブロック引数)" do
      expect(token_values("|x|")).to eq(["|", "x", "|"])
    end
  end

  # ============================================================
  # シングルクォート文字列
  # ============================================================
  describe "シングルクォート文字列" do
    it "内容は置換対象外" do
      expect(string_parts("'クラス 終わり'").join).to eq("クラス 終わり")
    end

    it "エスケープされたクォート" do
      parts = string_parts("'it\\\\'s'")
      expect(parts.join).to include("it")
    end

    it "空文字列" do
      tokens = tokenize("''")
      expect(tokens.map(&:type)).to eq([:other, :other])
    end

    it "\#{} はテキストのまま" do
      parts = string_parts(%q{'#{クラス}'})
      expect(parts.join).to include("\#{クラス}")
    end
  end

  # ============================================================
  # ダブルクォート文字列
  # ============================================================
  describe "ダブルクォート文字列" do
    it "内容は置換対象外" do
      expect(string_parts('"クラス 終わり"').join).to eq("クラス 終わり")
    end

    it "補間内はコードコンテキスト" do
      expect(word_tokens('"hello #{クラス名}"')).to eq(["クラス名"])
    end

    it "補間内の複雑な式" do
      expect(word_tokens('"#{a + b}"')).to eq(%w[a b])
    end

    it "複数の補間" do
      expect(word_tokens('"#{a}と#{b}"')).to eq(%w[a b])
    end

    it "エスケープシーケンス" do
      expect(string_parts('"\\n\\t"').join).to include('\\n', '\\t')
    end

    it "空文字列" do
      tokens = tokenize('""')
      expect(tokens.map(&:type)).to eq([:other, :other])
    end

    it "補間のない#" do
      parts = string_parts('"#コメントではない"')
      expect(parts.join).to include("#")
    end

    it "ネストしたブレースの補間" do
      tokens = tokenize('"#{hash[:key]}"')
      interps = tokens.select { |t| [:interp_begin, :interp_end].include?(t.type) }
      expect(interps.length).to eq(2)
    end
  end

  # ============================================================
  # コメント
  # ============================================================
  describe "行コメント" do
    it ":commentとして分類" do
      expect(comment_parts("クラス # コメント").first).to eq("# コメント")
    end

    it "行頭コメント" do
      expect(comment_parts("# 全体がコメント").first).to eq("# 全体がコメント")
    end

    it "コメント内のキーワードは維持" do
      part = comment_parts("# クラス 定義 終わり").first
      expect(part).to include("クラス")
    end

    it "補間と混同しない" do
      expect(tokenize('"#{変数}"').select { |t| t.type == :comment }).to be_empty
    end
  end

  describe "複数行コメント" do
    it "=begin...=end" do
      parts = comment_parts("=begin\nコメント内容\n=end")
      expect(parts.join).to include("コメント内容")
    end

    it "前後のコードは通常通り" do
      words = word_tokens("コード1\n=begin\nコメント\n=end\nコード2")
      expect(words).to include("コード1")
      expect(words).to include("コード2")
    end
  end

  # ============================================================
  # 正規表現
  # ============================================================
  describe "正規表現" do
    it "内容は置換対象外" do
      expect(string_parts("/クラス/").join).to eq("クラス")
    end

    it "フラグを保持" do
      tokens = tokenize("/パターン/i")
      others = tokens.select { |t| t.type == :other }
      expect(others.last.value).to eq("/i")
    end

    it "補間内はコード" do
      expect(word_tokens('/#{変数}/')).to eq(["変数"])
    end
  end

  # ============================================================
  # ヒアドキュメント
  # ============================================================
  describe "ヒアドキュメント" do
    it "本体は置換対象外" do
      parts = string_parts("<<~TEXT\nクラス 終わり\nTEXT")
      expect(parts.join).to include("クラス 終わり")
    end

    it "補間内はコード" do
      words = word_tokens("<<~TEXT\nhello \#{名前}\nTEXT")
      expect(words).to include("名前")
    end

    it "シングルクォートデリミタは補間なし" do
      words = word_tokens("<<~'TEXT'\n\\\#{クラス}\nTEXT")
      expect(words).not_to include("クラス")
    end
  end

  # ============================================================
  # パーセントリテラル
  # ============================================================
  describe "パーセントリテラル" do
    it "%q{}は補間なし" do
      expect(string_parts("%q{クラス}").join).to include("クラス")
    end

    it "%Q{}は補間あり" do
      expect(word_tokens('%Q{#{変数}}')).to include("変数")
    end

    it "%w[]は文字列配列" do
      expect(string_parts("%w[一 二 三]").join).to include("一")
    end

    it "%i[]はシンボル配列" do
      expect(string_parts("%i[名前 年齢]").join).to include("名前")
    end

    it "ネストした括弧" do
      source = "%q{外{内}外}"
      expect(tokenize(source).map(&:value).join).to eq(source)
    end
  end

  # ============================================================
  # バッククォート・シンボル文字列
  # ============================================================
  describe "バッククォート文字列" do
    it "内容は置換対象外" do
      expect(string_parts('`クラス コマンド`').join).to include("クラス")
    end

    it "補間内はコード" do
      expect(word_tokens('`echo #{変数}`')).to include("変数")
    end
  end

  describe "シンボル文字列" do
    it ':"..." は置換対象外' do
      expect(string_parts(':"クラス"').join).to eq("クラス")
    end

    it ":'...' は置換対象外" do
      expect(string_parts(":'クラス'").join).to eq("クラス")
    end
  end

  # ============================================================
  # ソース再構成
  # ============================================================
  describe "ソース再構成" do
    it "文字列を含むプログラム" do
      source = %{表示 "こんにちは、\#{名前}さん！"}
      expect(tokenize(source).map(&:value).join).to eq(source)
    end

    it "コメントを含むプログラム" do
      source = "# コメント\nクラス 犬\n終わり"
      expect(tokenize(source).map(&:value).join).to eq(source)
    end

    it "複雑なプログラム" do
      source = "クラス 動物\n  定義 初期化(名前)\n    @名前 = 名前\n  終わり\n終わり\n"
      expect(tokenize(source).map(&:value).join).to eq(source)
    end
  end
end

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

  describe "basic code tokenization" do
    it "tokenizes Japanese words" do
      tokens = tokenize("クラス 犬")
      words = tokens.select { |t| t.type == :word }
      expect(words.map(&:value)).to eq(%w[クラス 犬])
    end

    it "tokenizes English words" do
      tokens = tokenize("class Dog")
      words = tokens.select { |t| t.type == :word }
      expect(words.map(&:value)).to eq(%w[class Dog])
    end

    it "tokenizes mixed Japanese and English" do
      tokens = tokenize("クラス Dog")
      words = tokens.select { |t| t.type == :word }
      expect(words.map(&:value)).to eq(%w[クラス Dog])
    end

    it "preserves whitespace" do
      expect(token_values("クラス  犬")).to eq(["クラス", "  ", "犬"])
    end

    it "handles operators" do
      expect(token_values("a + b")).to eq(["a", " ", "+", " ", "b"])
    end

    it "handles words with ? and !" do
      expect(word_tokens("空? 含む? 保存!")).to eq(%w[空? 含む? 保存!])
    end
  end

  describe "single-quoted strings" do
    it "does not replace keywords inside single-quoted strings" do
      tokens = tokenize("'クラス 終わり'")
      string_parts = tokens.select { |t| t.type == :string_part }
      expect(string_parts.map(&:value).join).to eq("クラス 終わり")
    end

    it "handles escaped quotes" do
      tokens = tokenize("'it\\'s'")
      string_parts = tokens.select { |t| t.type == :string_part }
      expect(string_parts.map(&:value).join).to include("it")
    end
  end

  describe "double-quoted strings" do
    it "does not replace keywords in string content" do
      tokens = tokenize('"クラス 終わり"')
      string_parts = tokens.select { |t| t.type == :string_part }
      expect(string_parts.map(&:value).join).to eq("クラス 終わり")
    end

    it "handles interpolation as code context" do
      tokens = tokenize('"hello #{クラス名}"')
      words = tokens.select { |t| t.type == :word }
      expect(words.map(&:value)).to eq(["クラス名"])
    end

    it "handles escaped characters" do
      tokens = tokenize('"\\n\\t"')
      string_parts = tokens.select { |t| t.type == :string_part }
      expect(string_parts.map(&:value)).to eq(["\\n", "\\t"])
    end
  end

  describe "comments" do
    it "classifies line comments as :comment" do
      tokens = tokenize("クラス # コメント")
      comments = tokens.select { |t| t.type == :comment }
      expect(comments.first.value).to eq("# コメント")
    end

    it "does not confuse interpolation with comments" do
      tokens = tokenize('"#{変数}"')
      comments = tokens.select { |t| t.type == :comment }
      expect(comments).to be_empty
    end
  end

  describe "multi-line comments" do
    it "classifies =begin...=end as comments" do
      source = "=begin\nこれはコメント\n=end"
      tokens = tokenize(source)
      comments = tokens.select { |t| t.type == :comment }
      expect(comments.map(&:value).join).to include("これはコメント")
    end
  end

  describe "newlines and line tracking" do
    it "preserves newlines" do
      source = "クラス\n終わり"
      result = token_values(source).join
      expect(result).to eq("クラス\n終わり")
    end
  end

  describe "reconstruction" do
    it "reconstructs the original source" do
      source = "クラス 犬\n  定義 初期化(名前)\n    @名前 = 名前\n  終わり\n終わり"
      result = tokenize(source).map(&:value).join
      expect(result).to eq(source)
    end
  end
end

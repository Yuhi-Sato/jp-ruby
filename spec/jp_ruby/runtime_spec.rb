# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::Runtime do
  before(:all) do
    described_class.load!
  end

  describe "Kernel methods" do
    it "defines 表示 as alias for puts" do
      expect { 表示 "テスト" }.to output("テスト\n").to_stdout
    end

    it "defines 出力 as alias for print" do
      expect { 出力 "テスト" }.to output("テスト").to_stdout
    end

    it "defines 検査 as alias for p" do
      expect { 検査 "テスト" }.to output("\"テスト\"\n").to_stdout
    end
  end

  describe "Array methods" do
    let(:arr) { [1, 2, 3, 4, 5] }

    it "defines それぞれ for each" do
      result = []
      arr.それぞれ { |x| result << x }
      expect(result).to eq([1, 2, 3, 4, 5])
    end

    it "defines 変換 for map" do
      expect(arr.変換 { |x| x * 2 }).to eq([2, 4, 6, 8, 10])
    end

    it "defines 選択 for select" do
      expect(arr.選択 { |x| x > 3 }).to eq([4, 5])
    end

    it "defines 除外 for reject" do
      expect(arr.除外 { |x| x > 3 }).to eq([1, 2, 3])
    end

    it "defines 長さ for length" do
      expect(arr.長さ).to eq(5)
    end

    it "defines 空? for empty?" do
      expect([].空?).to be true
      expect(arr.空?).to be false
    end

    it "defines 含む? for include?" do
      expect(arr.含む?(3)).to be true
      expect(arr.含む?(6)).to be false
    end

    it "defines 最初 and 最後" do
      expect(arr.最初).to eq(1)
      expect(arr.最後).to eq(5)
    end

    it "defines 結合 for join" do
      expect(arr.結合(", ")).to eq("1, 2, 3, 4, 5")
    end

    it "defines 並べ替え for sort" do
      expect([3, 1, 2].並べ替え).to eq([1, 2, 3])
    end

    it "defines 逆順 for reverse" do
      expect(arr.逆順).to eq([5, 4, 3, 2, 1])
    end

    it "defines 一意 for uniq" do
      expect([1, 1, 2, 2, 3].一意).to eq([1, 2, 3])
    end
  end

  describe "Hash methods" do
    let(:hash) { { 名前: "太郎", 年齢: 20 } }

    it "defines 鍵一覧 for keys" do
      expect(hash.鍵一覧).to eq([:名前, :年齢])
    end

    it "defines 値一覧 for values" do
      expect(hash.値一覧).to eq(["太郎", 20])
    end

    it "defines 含む? for include?" do
      expect(hash.含む?(:名前)).to be true
    end

    it "defines 空? for empty?" do
      expect({}.空?).to be true
    end
  end

  describe "String methods" do
    let(:str) { "こんにちは世界" }

    it "defines 長さ for length" do
      expect(str.長さ).to eq(7)
    end

    it "defines 含む? for include?" do
      expect(str.含む?("世界")).to be true
    end

    it "defines 空? for empty?" do
      expect("".空?).to be true
      expect(str.空?).to be false
    end

    it "defines 分割 for split" do
      expect("a,b,c".分割(",")).to eq(%w[a b c])
    end

    it "defines 大文字 for upcase" do
      expect("hello".大文字).to eq("HELLO")
    end

    it "defines 小文字 for downcase" do
      expect("HELLO".小文字).to eq("hello")
    end

    it "defines 整数変換 for to_i" do
      expect("42".整数変換).to eq(42)
    end
  end

  describe "Integer methods" do
    it "defines 回 for times" do
      result = []
      3.回 { |i| result << i }
      expect(result).to eq([0, 1, 2])
    end

    it "defines 偶数? for even?" do
      expect(4.偶数?).to be true
      expect(3.偶数?).to be false
    end

    it "defines 奇数? for odd?" do
      expect(3.奇数?).to be true
      expect(4.奇数?).to be false
    end

    it "defines 絶対値 for abs" do
      expect(-5.絶対値).to eq(5)
    end
  end

  describe "Object methods" do
    it "defines 凍結 for freeze" do
      str = "test"
      str.凍結
      expect(str.frozen?).to be true
    end

    it "defines 凍結済み? for frozen?" do
      str = "test".freeze
      expect(str.凍結済み?).to be true
    end

    it "defines 複製 for dup" do
      original = [1, 2, 3]
      copy = original.複製
      expect(copy).to eq(original)
      expect(copy).not_to equal(original)
    end

    it "defines は? for is_a?" do
      expect("hello".は?(String)).to be true
    end
  end
end

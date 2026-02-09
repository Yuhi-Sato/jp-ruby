# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::Runtime do
  before(:all) do
    described_class.load!
  end

  # ============================================================
  # Kernel メソッド
  # ============================================================
  describe "Kernelメソッド" do
    it "表示 → puts" do
      expect { 表示 "テスト" }.to output("テスト\n").to_stdout
    end

    it "出力 → print" do
      expect { 出力 "テスト" }.to output("テスト").to_stdout
    end

    it "検査 → p" do
      expect { 検査 "テスト" }.to output("\"テスト\"\n").to_stdout
    end
  end

  # ============================================================
  # Array メソッド
  # ============================================================
  describe "Arrayメソッド" do
    let(:arr) { [1, 2, 3, 4, 5] }

    it "それぞれ → each" do
      result = []
      arr.それぞれ { |x| result << x }
      expect(result).to eq([1, 2, 3, 4, 5])
    end

    it "変換 → map" do
      expect(arr.変換 { |x| x * 2 }).to eq([2, 4, 6, 8, 10])
    end

    it "選択 → select" do
      expect(arr.選択 { |x| x > 3 }).to eq([4, 5])
    end

    it "除外 → reject" do
      expect(arr.除外 { |x| x > 3 }).to eq([1, 2, 3])
    end

    it "畳み込み → reduce" do
      expect(arr.畳み込み(0) { |sum, x| sum + x }).to eq(15)
    end

    it "並べ替え → sort" do
      expect([3, 1, 2].並べ替え).to eq([1, 2, 3])
    end

    it "逆順 → reverse" do
      expect(arr.逆順).to eq([5, 4, 3, 2, 1])
    end

    it "平坦化 → flatten" do
      expect([[1, 2], [3, 4]].平坦化).to eq([1, 2, 3, 4])
    end

    it "一意 → uniq" do
      expect([1, 1, 2, 2, 3].一意).to eq([1, 2, 3])
    end

    it "含む? → include?" do
      expect(arr.含む?(3)).to be true
      expect(arr.含む?(6)).to be false
    end

    it "追加 → push" do
      a = [1, 2]
      a.追加(3)
      expect(a).to eq([1, 2, 3])
    end

    it "長さ → length" do
      expect(arr.長さ).to eq(5)
    end

    it "大きさ → size" do
      expect(arr.大きさ).to eq(5)
    end

    it "最初 → first" do
      expect(arr.最初).to eq(1)
    end

    it "最後 → last" do
      expect(arr.最後).to eq(5)
    end

    it "空? → empty?" do
      expect([].空?).to be true
      expect(arr.空?).to be false
    end

    it "結合 → join" do
      expect(arr.結合(", ")).to eq("1, 2, 3, 4, 5")
    end

    it "個数 → count" do
      expect(arr.個数).to eq(5)
      expect(arr.個数 { |x| x > 3 }).to eq(2)
    end
  end

  # ============================================================
  # Hash メソッド
  # ============================================================
  describe "Hashメソッド" do
    let(:hash) { { 名前: "太郎", 年齢: 20 } }

    it "それぞれ → each" do
      result = []
      hash.それぞれ { |k, v| result << [k, v] }
      expect(result).to eq([[:名前, "太郎"], [:年齢, 20]])
    end

    it "鍵一覧 → keys" do
      expect(hash.鍵一覧).to eq([:名前, :年齢])
    end

    it "値一覧 → values" do
      expect(hash.値一覧).to eq(["太郎", 20])
    end

    it "長さ → length" do
      expect(hash.長さ).to eq(2)
    end

    it "含む? → include?" do
      expect(hash.含む?(:名前)).to be true
      expect(hash.含む?(:住所)).to be false
    end

    it "空? → empty?" do
      expect({}.空?).to be true
      expect(hash.空?).to be false
    end

    it "結合 → merge" do
      expect(hash.結合({ 住所: "東京" })).to include(住所: "東京")
    end

    it "削除 → delete" do
      h = { a: 1, b: 2 }
      h.削除(:a)
      expect(h).to eq({ b: 2 })
    end
  end

  # ============================================================
  # String メソッド
  # ============================================================
  describe "Stringメソッド" do
    it "長さ → length" do
      expect("こんにちは".長さ).to eq(5)
    end

    it "大きさ → size" do
      expect("hello".大きさ).to eq(5)
    end

    it "分割 → split" do
      expect("a,b,c".分割(",")).to eq(%w[a b c])
    end

    it "含む? → include?" do
      expect("こんにちは世界".含む?("世界")).to be true
      expect("こんにちは世界".含む?("宇宙")).to be false
    end

    it "置換 → gsub" do
      expect("hello world".置換("world", "Ruby")).to eq("hello Ruby")
    end

    it "大文字 → upcase" do
      expect("hello".大文字).to eq("HELLO")
    end

    it "小文字 → downcase" do
      expect("HELLO".小文字).to eq("hello")
    end

    it "除去 → strip" do
      expect("  hello  ".除去).to eq("hello")
    end

    it "空? → empty?" do
      expect("".空?).to be true
      expect("a".空?).to be false
    end

    it "逆順 → reverse" do
      expect("abc".逆順).to eq("cba")
    end

    it "文字列変換 → to_s" do
      expect("hello".文字列変換).to eq("hello")
    end

    it "整数変換 → to_i" do
      expect("42".整数変換).to eq(42)
    end

    it "小数変換 → to_f" do
      expect("3.14".小数変換).to eq(3.14)
    end
  end

  # ============================================================
  # Integer メソッド
  # ============================================================
  describe "Integerメソッド" do
    it "回 → times" do
      result = []
      3.回 { |i| result << i }
      expect(result).to eq([0, 1, 2])
    end

    it "偶数? → even?" do
      expect(4.偶数?).to be true
      expect(3.偶数?).to be false
    end

    it "奇数? → odd?" do
      expect(3.奇数?).to be true
      expect(4.奇数?).to be false
    end

    it "文字列変換 → to_s" do
      expect(42.文字列変換).to eq("42")
    end

    it "小数変換 → to_f" do
      expect(42.小数変換).to eq(42.0)
    end

    it "まで上 → upto" do
      result = []
      1.まで上(5) { |i| result << i }
      expect(result).to eq([1, 2, 3, 4, 5])
    end

    it "まで下 → downto" do
      result = []
      5.まで下(1) { |i| result << i }
      expect(result).to eq([5, 4, 3, 2, 1])
    end

    it "絶対値 → abs" do
      expect(-5.絶対値).to eq(5)
      expect(5.絶対値).to eq(5)
    end
  end

  # ============================================================
  # Float メソッド
  # ============================================================
  describe "Floatメソッド" do
    it "整数変換 → to_i" do
      expect(3.14.整数変換).to eq(3)
    end

    it "文字列変換 → to_s" do
      expect(3.14.文字列変換).to eq("3.14")
    end

    it "切り上げ → ceil" do
      expect(3.14.切り上げ).to eq(4)
    end

    it "切り捨て → floor" do
      expect(3.14.切り捨て).to eq(3)
    end

    it "四捨五入 → round" do
      expect(3.5.四捨五入).to eq(4)
      expect(3.4.四捨五入).to eq(3)
    end

    it "絶対値 → abs" do
      expect(-3.14.絶対値).to eq(3.14)
    end
  end

  # ============================================================
  # Object メソッド
  # ============================================================
  describe "Objectメソッド" do
    it "凍結 → freeze" do
      str = +"test"
      str.凍結
      expect(str.frozen?).to be true
    end

    it "凍結済み? → frozen?" do
      expect("test".freeze.凍結済み?).to be true
      s = +"test"
      expect(s.凍結済み?).to be false
    end

    it "複製 → dup" do
      original = [1, 2, 3]
      copy = original.複製
      expect(copy).to eq(original)
      expect(copy).not_to equal(original)
    end

    it "は? → is_a?" do
      expect("hello".は?(String)).to be true
      expect(42.は?(Integer)).to be true
      expect("hello".は?(Integer)).to be false
    end

    it "応答する? → respond_to?" do
      expect("hello".応答する?(:length)).to be true
      expect("hello".応答する?(:存在しない)).to be false
    end
  end
end

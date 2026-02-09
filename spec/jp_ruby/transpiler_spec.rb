# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::Transpiler do
  def transpile(source)
    described_class.new(source).transpile
  end

  describe "keyword replacement" do
    it "replaces クラス with class" do
      expect(transpile("クラス")).to eq("class")
    end

    it "replaces 定義 with def" do
      expect(transpile("定義")).to eq("def")
    end

    it "replaces 終わり with end" do
      expect(transpile("終わり")).to eq("end")
    end

    it "replaces もし with if" do
      expect(transpile("もし")).to eq("if")
    end

    it "replaces でなければ with else" do
      expect(transpile("でなければ")).to eq("else")
    end

    it "replaces そうでなければ with elsif" do
      expect(transpile("そうでなければ")).to eq("elsif")
    end

    it "replaces 真/偽/無" do
      expect(transpile("真")).to eq("true")
      expect(transpile("偽")).to eq("false")
      expect(transpile("無")).to eq("nil")
    end

    it "replaces 表示 with puts" do
      expect(transpile("表示")).to eq("puts")
    end

    it "replaces 自分 with self" do
      expect(transpile("自分")).to eq("self")
    end

    it "replaces 戻す with return" do
      expect(transpile("戻す")).to eq("return")
    end

    it "replaces それ with it (Ruby 4.0)" do
      expect(transpile("それ")).to eq("it")
    end

    it "replaces ラクター with Ractor" do
      expect(transpile("ラクター")).to eq("Ractor")
    end

    it "replaces データ with Data" do
      expect(transpile("データ")).to eq("Data")
    end
  end

  describe "class name C-prefix" do
    it "adds C prefix to Japanese class names" do
      source = "クラス 犬\n終わり"
      result = transpile(source)
      expect(result).to eq("class C犬\nend")
    end

    it "adds C prefix for inheritance" do
      source = "クラス 犬 < 動物\n終わり\nクラス 動物\n終わり"
      result = transpile(source)
      expect(result).to include("class C犬 < C動物")
      expect(result).to include("class C動物")
    end

    it "adds C prefix to module names" do
      source = "モジュール 挨拶\n終わり"
      result = transpile(source)
      expect(result).to eq("module C挨拶\nend")
    end

    it "adds C prefix when used as reference" do
      source = "クラス 犬\n終わり\n犬.新規"
      result = transpile(source)
      expect(result).to include("C犬.new")
    end

    it "does not add C prefix to English class names" do
      source = "クラス Dog\n終わり"
      result = transpile(source)
      expect(result).to eq("class Dog\nend")
    end
  end

  describe "string preservation" do
    it "does not replace keywords inside double-quoted strings" do
      source = '表示 "クラス 終わり"'
      result = transpile(source)
      expect(result).to eq('puts "クラス 終わり"')
    end

    it "does not replace keywords inside single-quoted strings" do
      source = "表示 'クラス 終わり'"
      result = transpile(source)
      expect(result).to eq("puts 'クラス 終わり'")
    end

    it "replaces keywords inside string interpolation" do
      source = 'クラス 犬\n終わり\n表示 "#{犬}"'
      result = transpile(source)
      expect(result).to include('"#{C犬}"')
    end
  end

  describe "comment preservation" do
    it "does not replace keywords inside comments" do
      source = "# クラス定義\nクラス 犬\n終わり"
      result = transpile(source)
      expect(result).to include("# クラス定義")
      expect(result).to include("class C犬")
    end
  end

  describe "line preservation" do
    it "preserves the number of lines" do
      source = "クラス 犬\n  定義 吠える\n    表示 \"ワン\"\n  終わり\n終わり"
      result = transpile(source)
      expect(result.lines.count).to eq(source.lines.count)
    end
  end

  describe "complete programs" do
    it "transpiles a hello world program" do
      source = '表示 "こんにちは、世界！"'
      result = transpile(source)
      expect(result).to eq('puts "こんにちは、世界！"')
    end

    it "transpiles a class definition" do
      source = <<~JRB
        クラス 動物
          定義 初期化(名前)
            @名前 = 名前
          終わり
        終わり
      JRB

      result = transpile(source)
      expect(result).to include("class C動物")
      expect(result).to include("def initialize(名前)")
      expect(result).to include("@名前 = 名前")
      expect(result).to include("end")
    end

    it "transpiles control flow" do
      source = <<~JRB
        もし 真
          表示 "はい"
        でなければ
          表示 "いいえ"
        終わり
      JRB

      result = transpile(source)
      expect(result).to include("if true")
      expect(result).to include('puts "はい"')
      expect(result).to include("else")
      expect(result).to include('puts "いいえ"')
    end

    it "transpiles pattern matching (Ruby 4.0 case/in)" do
      source = <<~JRB
        場合 値
        中の 1
          表示 "一"
        中の 2
          表示 "二"
        終わり
      JRB

      result = transpile(source)
      expect(result).to include("case 値")
      expect(result).to include("in 1")
      expect(result).to include("in 2")
    end

    it "transpiles it block parameter (Ruby 4.0)" do
      source = '[1, 2, 3].変換 { それ * 2 }'
      result = transpile(source)
      expect(result).to include("it * 2")
    end
  end
end

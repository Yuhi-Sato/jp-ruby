# frozen_string_literal: true

require "spec_helper"

RSpec.describe JpRuby::Transpiler do
  def transpile(source)
    described_class.new(source).transpile
  end

  # ============================================================
  # 全キーワード変換テスト
  # ============================================================
  describe "定義・構造キーワード" do
    it "クラス → class" do
      expect(transpile("クラス")).to eq("class")
    end

    it "モジュール → module" do
      expect(transpile("モジュール")).to eq("module")
    end

    it "定義 → def" do
      expect(transpile("定義")).to eq("def")
    end

    it "終わり → end" do
      expect(transpile("終わり")).to eq("end")
    end

    it "初期化 → initialize" do
      expect(transpile("初期化")).to eq("initialize")
    end

    it "新規 → new" do
      expect(transpile("新規")).to eq("new")
    end
  end

  describe "制御構文キーワード" do
    it "もし → if" do
      expect(transpile("もし")).to eq("if")
    end

    it "そうでなければ → elsif" do
      expect(transpile("そうでなければ")).to eq("elsif")
    end

    it "でなければ → else" do
      expect(transpile("でなければ")).to eq("else")
    end

    it "でない限り → unless" do
      expect(transpile("でない限り")).to eq("unless")
    end

    it "場合 → case" do
      expect(transpile("場合")).to eq("case")
    end

    it "条件 → when" do
      expect(transpile("条件")).to eq("when")
    end

    it "そして → then" do
      expect(transpile("そして")).to eq("then")
    end
  end

  describe "ループ・ブロックキーワード" do
    it "繰り返す → while" do
      expect(transpile("繰り返す")).to eq("while")
    end

    it "まで → until" do
      expect(transpile("まで")).to eq("until")
    end

    it "繰り返し → for" do
      expect(transpile("繰り返し")).to eq("for")
    end

    it "中の → in" do
      expect(transpile("中の")).to eq("in")
    end

    it "する → do" do
      expect(transpile("する")).to eq("do")
    end
  end

  describe "リテラルキーワード" do
    it "真 → true" do
      expect(transpile("真")).to eq("true")
    end

    it "偽 → false" do
      expect(transpile("偽")).to eq("false")
    end

    it "無 → nil" do
      expect(transpile("無")).to eq("nil")
    end
  end

  describe "参照キーワード" do
    it "自分 → self" do
      expect(transpile("自分")).to eq("self")
    end

    it "親 → super" do
      expect(transpile("親")).to eq("super")
    end
  end

  describe "フロー制御キーワード" do
    it "戻す → return" do
      expect(transpile("戻す")).to eq("return")
    end

    it "次へ → next" do
      expect(transpile("次へ")).to eq("next")
    end

    it "中断 → break" do
      expect(transpile("中断")).to eq("break")
    end

    it "譲る → yield" do
      expect(transpile("譲る")).to eq("yield")
    end

    it "やり直す → redo" do
      expect(transpile("やり直す")).to eq("redo")
    end

    it "再試行 → retry" do
      expect(transpile("再試行")).to eq("retry")
    end
  end

  describe "例外処理キーワード" do
    it "始まり → begin" do
      expect(transpile("始まり")).to eq("begin")
    end

    it "救済 → rescue" do
      expect(transpile("救済")).to eq("rescue")
    end

    it "確保 → ensure" do
      expect(transpile("確保")).to eq("ensure")
    end

    it "発生 → raise" do
      expect(transpile("発生")).to eq("raise")
    end
  end

  describe "モジュール・アクセスキーワード" do
    it "取り込む → include" do
      expect(transpile("取り込む")).to eq("include")
    end

    it "拡張 → extend" do
      expect(transpile("拡張")).to eq("extend")
    end

    it "公開 → public" do
      expect(transpile("公開")).to eq("public")
    end

    it "非公開 → private" do
      expect(transpile("非公開")).to eq("private")
    end

    it "保護 → protected" do
      expect(transpile("保護")).to eq("protected")
    end

    it "別名 → alias" do
      expect(transpile("別名")).to eq("alias")
    end

    it "未定義 → undef" do
      expect(transpile("未定義")).to eq("undef")
    end
  end

  describe "論理演算子キーワード" do
    it "かつ → and" do
      expect(transpile("かつ")).to eq("and")
    end

    it "または → or" do
      expect(transpile("または")).to eq("or")
    end

    it "ではない → not" do
      expect(transpile("ではない")).to eq("not")
    end
  end

  describe "読み込みキーワード" do
    it "必要 → require" do
      expect(transpile("必要")).to eq("require")
    end

    it "相対必要 → require_relative" do
      expect(transpile("相対必要")).to eq("require_relative")
    end
  end

  describe "入出力キーワード" do
    it "表示 → puts" do
      expect(transpile("表示")).to eq("puts")
    end

    it "出力 → print" do
      expect(transpile("出力")).to eq("print")
    end

    it "検査 → p" do
      expect(transpile("検査")).to eq("p")
    end
  end

  describe "属性キーワード" do
    it "属性 → attr_accessor" do
      expect(transpile("属性")).to eq("attr_accessor")
    end

    it "読み属性 → attr_reader" do
      expect(transpile("読み属性")).to eq("attr_reader")
    end

    it "書き属性 → attr_writer" do
      expect(transpile("書き属性")).to eq("attr_writer")
    end
  end

  describe "メタキーワード" do
    it "定義済み? → defined?" do
      expect(transpile("定義済み?")).to eq("defined?")
    end

    it "ブロック渡し? → block_given?" do
      expect(transpile("ブロック渡し?")).to eq("block_given?")
    end
  end

  describe "特殊変数キーワード" do
    it "__ファイル__ → __FILE__" do
      expect(transpile("__ファイル__")).to eq("__FILE__")
    end

    it "__行番号__ → __LINE__" do
      expect(transpile("__行番号__")).to eq("__LINE__")
    end

    it "__エンコード__ → __ENCODING__" do
      expect(transpile("__エンコード__")).to eq("__ENCODING__")
    end
  end

  describe "Ruby 4.0 キーワード" do
    it "それ → it (ブロックパラメータ)" do
      expect(transpile("それ")).to eq("it")
    end

    it "ラクター → Ractor" do
      expect(transpile("ラクター")).to eq("Ractor")
    end

    it "データ → Data" do
      expect(transpile("データ")).to eq("Data")
    end
  end

  # ============================================================
  # クラス名Cプレフィックス
  # ============================================================
  describe "クラス名Cプレフィックス" do
    it "日本語クラス名にCを付与" do
      expect(transpile("クラス 犬\n終わり")).to eq("class C犬\nend")
    end

    it "継承元にもCを付与" do
      source = "クラス 犬 < 動物\n終わり\nクラス 動物\n終わり"
      result = transpile(source)
      expect(result).to include("class C犬 < C動物")
      expect(result).to include("class C動物")
    end

    it "モジュール名にCを付与" do
      expect(transpile("モジュール 挨拶\n終わり")).to eq("module C挨拶\nend")
    end

    it "参照時にもCを付与" do
      result = transpile("クラス 犬\n終わり\n犬.新規")
      expect(result).to include("C犬.new")
    end

    it "英語クラス名にはCを付与しない" do
      expect(transpile("クラス Dog\n終わり")).to eq("class Dog\nend")
    end

    it "複数のクラスを扱う" do
      source = "クラス 動物\n終わり\nクラス 犬\n終わり\nクラス 猫\n終わり"
      result = transpile(source)
      expect(result).to include("class C動物")
      expect(result).to include("class C犬")
      expect(result).to include("class C猫")
    end
  end

  # ============================================================
  # 文字列内の保護
  # ============================================================
  describe "文字列内の保護" do
    it "ダブルクォート内のキーワードは置換しない" do
      expect(transpile('表示 "クラス 終わり"')).to eq('puts "クラス 終わり"')
    end

    it "シングルクォート内のキーワードは置換しない" do
      expect(transpile("表示 'クラス 終わり'")).to eq("puts 'クラス 終わり'")
    end

    it "補間内のキーワードは置換する" do
      result = transpile("クラス 犬\n終わり\n表示 \"" + '#{犬}' + "\"")
      expect(result).to include('#{C犬}')
    end
  end

  # ============================================================
  # コメント内の保護
  # ============================================================
  describe "コメント内の保護" do
    it "行コメント内のキーワードは置換しない" do
      result = transpile("# クラス定義\nクラス 犬\n終わり")
      expect(result).to include("# クラス定義")
      expect(result).to include("class C犬")
    end

    it "複数行コメント内のキーワードは置換しない" do
      source = "=begin\nクラス 定義\n=end\nクラス 犬\n終わり"
      result = transpile(source)
      expect(result).to include("class C犬")
    end
  end

  # ============================================================
  # 行番号保持
  # ============================================================
  describe "行番号保持" do
    it "変換前後で行数が同じ" do
      source = "クラス 犬\n  定義 吠える\n    表示 \"ワン\"\n  終わり\n終わり"
      expect(transpile(source).lines.count).to eq(source.lines.count)
    end
  end

  # ============================================================
  # 完全なプログラムのトランスパイル
  # ============================================================
  describe "完全なプログラム" do
    it "Hello World" do
      expect(transpile('表示 "こんにちは、世界！"')).to eq('puts "こんにちは、世界！"')
    end

    it "クラス定義" do
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

    it "if/elsif/else" do
      source = <<~JRB
        もし 真
          表示 "はい"
        そうでなければ 偽
          表示 "多分"
        でなければ
          表示 "いいえ"
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("if true")
      expect(result).to include("elsif false")
      expect(result).to include("else")
      expect(result).to include("end")
    end

    it "unless" do
      source = "でない限り 偽\n  表示 \"実行\"\n終わり"
      result = transpile(source)
      expect(result).to include("unless false")
    end

    it "while ループ" do
      source = "繰り返す 真\n  中断\n終わり"
      result = transpile(source)
      expect(result).to include("while true")
      expect(result).to include("break")
    end

    it "until ループ" do
      source = "まで 偽\n  中断\n終わり"
      result = transpile(source)
      expect(result).to include("until false")
    end

    it "for ループ" do
      source = "繰り返し i 中の [1, 2, 3] する\n  表示 i\n終わり"
      result = transpile(source)
      expect(result).to include("for i in [1, 2, 3] do")
    end

    it "case/when" do
      source = <<~JRB
        場合 値
        条件 1
          表示 "一"
        条件 2
          表示 "二"
        でなければ
          表示 "他"
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("case 値")
      expect(result).to include("when 1")
      expect(result).to include("when 2")
      expect(result).to include("else")
    end

    it "case/in パターンマッチング" do
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

    it "begin/rescue/ensure" do
      source = <<~JRB
        始まり
          発生 "エラー"
        救済 => e
          表示 e
        確保
          表示 "完了"
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("begin")
      expect(result).to include("raise")
      expect(result).to include("rescue => e")
      expect(result).to include("ensure")
    end

    it "モジュールとinclude" do
      source = <<~JRB
        モジュール 挨拶
          定義 こんにちは
            表示 "こんにちは"
          終わり
        終わり

        クラス 人
          取り込む 挨拶
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("module C挨拶")
      expect(result).to include("include C挨拶")
    end

    it "アクセス修飾子" do
      source = <<~JRB
        クラス 人
          公開
          定義 名前
          終わり

          非公開
          定義 秘密
          終わり

          保護
          定義 内部
          終わり
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("public")
      expect(result).to include("private")
      expect(result).to include("protected")
    end

    it "属性定義" do
      source = <<~JRB
        クラス 人
          属性 :名前, :年齢
          読み属性 :ID
          書き属性 :パスワード
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("attr_accessor :名前, :年齢")
      expect(result).to include("attr_reader :ID")
      expect(result).to include("attr_writer :パスワード")
    end

    it "yield と block_given?" do
      source = <<~JRB
        定義 実行
          もし ブロック渡し?
            譲る
          終わり
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("if block_given?")
      expect(result).to include("yield")
    end

    it "return / next / break" do
      source = <<~JRB
        定義 メソッド
          戻す 42
        終わり

        [1,2,3].それぞれ する |i|
          次へ もし i == 1
          中断 もし i == 3
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("return 42")
      expect(result).to include("next if")
      expect(result).to include("break if")
    end

    it "self と super" do
      source = <<~JRB
        クラス 子 < 親クラス
          定義 初期化
            親
            自分
          終わり
        終わり
      JRB
      result = transpile(source)
      expect(result).to include("super")
      expect(result).to include("self")
    end

    it "alias" do
      source = "別名 :新しい名前 :古い名前"
      result = transpile(source)
      expect(result).to include("alias :新しい名前 :古い名前")
    end

    it "論理演算子" do
      source = "真 かつ 偽 または 真"
      result = transpile(source)
      expect(result).to eq("true and false or true")
    end

    it "not" do
      source = "ではない 真"
      result = transpile(source)
      expect(result).to eq("not true")
    end

    it "require" do
      source = '必要 "json"'
      result = transpile(source)
      expect(result).to eq('require "json"')
    end

    it "require_relative" do
      source = '相対必要 "helper"'
      result = transpile(source)
      expect(result).to eq('require_relative "helper"')
    end

    it "defined?" do
      source = "定義済み? 変数"
      result = transpile(source)
      expect(result).to eq("defined? 変数")
    end

    it "itブロックパラメータ (Ruby 4.0)" do
      source = "[1, 2, 3].変換 { それ * 2 }"
      result = transpile(source)
      expect(result).to include("it * 2")
    end

    it "Ractor (Ruby 4.0)" do
      source = "ラクター.新規 { 42 }"
      result = transpile(source)
      expect(result).to eq("Ractor.new { 42 }")
    end

    it "Data (Ruby 4.0)" do
      source = "データ.定義(:x, :y)"
      result = transpile(source)
      expect(result).to eq("Data.def(:x, :y)")
    end

    it "__FILE__ / __LINE__ / __ENCODING__" do
      expect(transpile("__ファイル__")).to eq("__FILE__")
      expect(transpile("__行番号__")).to eq("__LINE__")
      expect(transpile("__エンコード__")).to eq("__ENCODING__")
    end
  end
end

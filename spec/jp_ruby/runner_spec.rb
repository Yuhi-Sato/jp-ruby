# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe JpRuby::Runner do
  def run_jrb(source, **options)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test.jrb")
      File.write(path, source, encoding: "UTF-8")

      if options[:dump]
        runner = described_class.new(path, dump: true)
        output = capture_stdout { runner.run }
        return output
      end

      runner = described_class.new(path, options)
      capture_stdout { runner.run }
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  # ============================================================
  # 基本実行
  # ============================================================
  describe "基本実行" do
    it "Hello World" do
      expect(run_jrb('表示 "こんにちは"')).to eq("こんにちは\n")
    end

    it "算術演算" do
      expect(run_jrb("表示 1 + 2")).to eq("3\n")
      expect(run_jrb("表示 10 - 3")).to eq("7\n")
      expect(run_jrb("表示 4 * 5")).to eq("20\n")
      expect(run_jrb("表示 10 / 2")).to eq("5\n")
      expect(run_jrb("表示 10 % 3")).to eq("1\n")
    end

    it "文字列連結" do
      expect(run_jrb('表示 "hello" + " " + "world"')).to eq("hello world\n")
    end

    it "変数代入" do
      source = "x = 42\n表示 x"
      expect(run_jrb(source)).to eq("42\n")
    end

    it "日本語変数名" do
      source = "名前 = \"太郎\"\n表示 名前"
      expect(run_jrb(source)).to eq("太郎\n")
    end
  end

  # ============================================================
  # 制御構文の実行
  # ============================================================
  describe "制御構文" do
    it "if/else" do
      source = <<~JRB
        もし 真
          表示 "はい"
        でなければ
          表示 "いいえ"
        終わり
      JRB
      expect(run_jrb(source)).to eq("はい\n")
    end

    it "if/elsif/else" do
      source = <<~JRB
        値 = 5
        もし 値 > 10
          表示 "大"
        そうでなければ 値 > 3
          表示 "中"
        でなければ
          表示 "小"
        終わり
      JRB
      expect(run_jrb(source)).to eq("中\n")
    end

    it "unless" do
      source = <<~JRB
        でない限り 偽
          表示 "実行された"
        終わり
      JRB
      expect(run_jrb(source)).to eq("実行された\n")
    end

    it "while ループ" do
      source = <<~JRB
        i = 0
        繰り返す i < 3
          表示 i
          i = i + 1
        終わり
      JRB
      expect(run_jrb(source)).to eq("0\n1\n2\n")
    end

    it "until ループ" do
      source = <<~JRB
        i = 0
        まで i >= 3
          表示 i
          i = i + 1
        終わり
      JRB
      expect(run_jrb(source)).to eq("0\n1\n2\n")
    end

    it "case/when" do
      source = <<~JRB
        値 = 2
        場合 値
        条件 1
          表示 "一"
        条件 2
          表示 "二"
        条件 3
          表示 "三"
        でなければ
          表示 "他"
        終わり
      JRB
      expect(run_jrb(source)).to eq("二\n")
    end

    it "後置if" do
      source = '表示 "はい" もし 真'
      expect(run_jrb(source)).to eq("はい\n")
    end

    it "後置unless" do
      source = '表示 "はい" でない限り 偽'
      expect(run_jrb(source)).to eq("はい\n")
    end

    it "三項演算子的な使い方(if修飾)" do
      source = "x = 真 ? 1 : 0\n表示 x"
      expect(run_jrb(source)).to eq("1\n")
    end
  end

  # ============================================================
  # クラス・モジュール
  # ============================================================
  describe "クラス・モジュール" do
    it "クラス定義とインスタンス化" do
      source = <<~JRB
        クラス 挨拶
          定義 初期化(メッセージ)
            @メッセージ = メッセージ
          終わり

          定義 表示する
            表示 @メッセージ
          終わり
        終わり

        挨拶.新規("こんにちは").表示する
      JRB
      expect(run_jrb(source)).to eq("こんにちは\n")
    end

    it "クラス継承" do
      source = <<~JRB
        クラス 動物
          定義 初期化(名前)
            @名前 = 名前
          終わり
          定義 名前取得
            @名前
          終わり
        終わり

        クラス 犬 < 動物
          定義 吠える
            表示 "\#{@名前}:ワン"
          終わり
        終わり

        ポチ = 犬.新規("ポチ")
        ポチ.吠える
      JRB
      expect(run_jrb(source)).to eq("ポチ:ワン\n")
    end

    it "モジュールのinclude" do
      source = <<~JRB
        モジュール 挨拶機能
          定義 こんにちは
            表示 "こんにちは"
          終わり
        終わり

        クラス 人
          取り込む 挨拶機能
        終わり

        人.新規.こんにちは
      JRB
      expect(run_jrb(source)).to eq("こんにちは\n")
    end

    it "attr_accessor" do
      source = <<~JRB
        クラス 人
          属性 :名前
        終わり

        太郎 = 人.新規
        太郎.名前 = "太郎"
        表示 太郎.名前
      JRB
      expect(run_jrb(source)).to eq("太郎\n")
    end

    it "privateメソッド" do
      source = <<~JRB
        クラス 秘密
          定義 公開メソッド
            表示 秘密メソッド
          終わり

          非公開

          定義 秘密メソッド
            "秘密の値"
          終わり
        終わり

        秘密.新規.公開メソッド
      JRB
      expect(run_jrb(source)).to eq("秘密の値\n")
    end
  end

  # ============================================================
  # 例外処理
  # ============================================================
  describe "例外処理" do
    it "begin/rescue" do
      source = <<~JRB
        始まり
          発生 "テストエラー"
        救済 => e
          表示 e.message
        終わり
      JRB
      expect(run_jrb(source)).to eq("テストエラー\n")
    end

    it "begin/rescue/ensure" do
      source = <<~JRB
        始まり
          発生 "エラー"
        救済
          表示 "救済した"
        確保
          表示 "確保した"
        終わり
      JRB
      expect(run_jrb(source)).to eq("救済した\n確保した\n")
    end
  end

  # ============================================================
  # ブロック・イテレータ
  # ============================================================
  describe "ブロック・イテレータ" do
    it "do...end ブロック" do
      source = <<~JRB
        [1, 2, 3].それぞれ する |x|
          表示 x
        終わり
      JRB
      expect(run_jrb(source)).to eq("1\n2\n3\n")
    end

    it "波括弧ブロック" do
      source = <<~JRB
        結果 = [1, 2, 3].変換 { |x| x * 10 }
        検査 結果
      JRB
      expect(run_jrb(source)).to eq("[10, 20, 30]\n")
    end

    it "yield" do
      source = <<~JRB
        定義 二回実行
          譲る
          譲る
        終わり

        二回実行 する
          表示 "実行"
        終わり
      JRB
      expect(run_jrb(source)).to eq("実行\n実行\n")
    end

    it "timesイテレータ" do
      source = <<~JRB
        3.回 する |i|
          表示 i
        終わり
      JRB
      expect(run_jrb(source)).to eq("0\n1\n2\n")
    end

    it "next と break" do
      source = <<~JRB
        [1, 2, 3, 4, 5].それぞれ する |i|
          次へ もし i == 2
          中断 もし i == 4
          表示 i
        終わり
      JRB
      expect(run_jrb(source)).to eq("1\n3\n")
    end
  end

  # ============================================================
  # メソッド定義
  # ============================================================
  describe "メソッド定義" do
    it "引数付きメソッド" do
      source = <<~JRB
        定義 足し算(a, b)
          戻す a + b
        終わり
        表示 足し算(3, 4)
      JRB
      expect(run_jrb(source)).to eq("7\n")
    end

    it "デフォルト引数" do
      source = <<~JRB
        定義 挨拶(名前 = "世界")
          表示 "こんにちは、\#{名前}！"
        終わり
        挨拶
        挨拶("太郎")
      JRB
      expect(run_jrb(source)).to eq("こんにちは、世界！\nこんにちは、太郎！\n")
    end

    it "可変長引数" do
      source = <<~JRB
        定義 合計(*数値)
          表示 数値.畳み込み(0) { |合計, n| 合計 + n }
        終わり
        合計(1, 2, 3, 4, 5)
      JRB
      expect(run_jrb(source)).to eq("15\n")
    end
  end

  # ============================================================
  # 論理演算
  # ============================================================
  describe "論理演算" do
    it "and / or" do
      source = <<~JRB
        表示 (真 かつ 偽)
        表示 (真 または 偽)
      JRB
      expect(run_jrb(source)).to eq("false\ntrue\n")
    end

    it "not" do
      source = "表示 (ではない 真)"
      expect(run_jrb(source)).to eq("false\n")
    end
  end

  # ============================================================
  # 文字列内保護
  # ============================================================
  describe "文字列内保護" do
    it "文字列内のキーワードは変換されない" do
      source = '表示 "クラス 定義 終わり"'
      expect(run_jrb(source)).to eq("クラス 定義 終わり\n")
    end

    it "コメント内のキーワードは無視される" do
      source = "# クラス 定義\n表示 \"OK\""
      expect(run_jrb(source)).to eq("OK\n")
    end
  end

  # ============================================================
  # --dump オプション
  # ============================================================
  describe "--dump オプション" do
    it "変換後のRubyコードを出力" do
      output = run_jrb('表示 "テスト"', dump: true)
      expect(output.strip).to eq('puts "テスト"')
    end

    it "クラス定義のダンプ" do
      source = "クラス 犬\n  定義 吠える\n    表示 \"ワン\"\n  終わり\n終わり"
      output = run_jrb(source, dump: true)
      expect(output).to include("class C犬")
      expect(output).to include("def 吠える")
    end
  end

  # ============================================================
  # エラーハンドリング
  # ============================================================
  describe "エラーハンドリング" do
    it "構文エラーでTranspileErrorを発生" do
      expect { run_jrb("定義\n終わり") }.to raise_error(JpRuby::TranspileError)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "yaml"

RSpec.describe JpRuby::Config do
  def write_config(dir, content)
    path = File.join(dir, ".jp-ruby.yml")
    File.write(path, content, encoding: "UTF-8")
    path
  end

  # ============================================================
  # 設定ファイルの検索
  # ============================================================
  describe ".discover" do
    it "explicit_pathが指定された場合、そのパスを返す" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: 組")
        expect(described_class.discover(explicit_path: path)).to eq(path)
      end
    end

    it "explicit_pathが存在しない場合、ConfigErrorを発生" do
      expect {
        described_class.discover(explicit_path: "/nonexistent/.jp-ruby.yml")
      }.to raise_error(JpRuby::ConfigError, /設定ファイルが見つかりません/)
    end

    it "input_fileと同じディレクトリの.jp-ruby.ymlを検索する" do
      Dir.mktmpdir do |dir|
        config_path = write_config(dir, "Keyword:\n  class: 組")
        input_file = File.join(dir, "test.jrb")
        File.write(input_file, "")

        expect(described_class.discover(input_file: input_file)).to eq(config_path)
      end
    end

    it "設定ファイルが見つからない場合、nilを返す" do
      Dir.mktmpdir do |dir|
        input_file = File.join(dir, "test.jrb")
        # Change pwd to the tmp dir to avoid finding .jp-ruby.yml in the real project
        result = Dir.chdir(dir) { described_class.discover(input_file: input_file) }
        expect(result).to be_nil
      end
    end
  end

  # ============================================================
  # YAMLの読み込みとバリデーション
  # ============================================================
  describe "YAML読み込み" do
    it "Keywordセクションのみの設定を読み込める" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: 組\n  def: メソッド定義")
        config = described_class.new(path)
        expect(config.keyword_overrides).to eq({ "class" => "組", "def" => "メソッド定義" })
        expect(config.runtime_overrides).to be_empty
      end
    end

    it "ランタイムセクションのみの設定を読み込める" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Array:
            each: それぞれの要素
        YAML
        path = write_config(dir, yaml)
        config = described_class.new(path)
        expect(config.keyword_overrides).to be_empty
        expect(config.runtime_overrides).to eq({ "Array" => { "each" => "それぞれの要素" } })
      end
    end

    it "両方のセクションを含む設定を読み込める" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Keyword:
            class: 組
          Array:
            each: それぞれの要素
        YAML
        path = write_config(dir, yaml)
        config = described_class.new(path)
        expect(config.keyword_overrides).to eq({ "class" => "組" })
        expect(config.runtime_overrides).to eq({ "Array" => { "each" => "それぞれの要素" } })
      end
    end

    it "config_pathがnilの場合、デフォルト設定を使用" do
      config = described_class.new(nil)
      expect(config.keyword_overrides).to be_empty
      expect(config.runtime_overrides).to be_empty
    end
  end

  # ============================================================
  # バリデーションエラー
  # ============================================================
  describe "バリデーション" do
    it "存在しないクラス名でConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Unknown:\n  key: value")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /不明なクラス/)
      end
    end

    it "セクションの値がハッシュでない場合、ConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword: invalid")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /ハッシュである必要があります/)
      end
    end

    it "空のキーワード値でConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: \"\"")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /空のキーワードは許可されていません/)
      end
    end

    it "空のエイリアス値でConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Array:\n  each: \"\"")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /空のエイリアスは許可されていません/)
      end
    end

    it "不正なYAML構文でConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: [invalid")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /YAML構文エラー/)
      end
    end

    it "ファイル内容がハッシュでない場合、ConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "- item1\n- item2")
        expect { described_class.new(path) }.to raise_error(JpRuby::ConfigError, /形式が正しくありません/)
      end
    end
  end

  # ============================================================
  # キーワードマップのビルド
  # ============================================================
  describe "#build_keyword_map" do
    it "オーバーライドなしでデフォルトマップを返す" do
      config = described_class.new(nil)
      expect(config.build_keyword_map).to eq(JpRuby::Keywords::DEFAULT_KEYWORD_MAP)
    end

    it "キーワードの上書きが正しく適用される" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: 組")
        config = described_class.new(path)
        keyword_map = config.build_keyword_map

        # 「組」がclassにマッピングされる
        expect(keyword_map["組"]).to eq("class")
        # 元の「クラス」はなくなる
        expect(keyword_map["クラス"]).to be_nil
      end
    end

    it "新しいキーワードの追加ができる" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  lambda: ラムダ")
        config = described_class.new(path)
        keyword_map = config.build_keyword_map

        expect(keyword_map["ラムダ"]).to eq("lambda")
      end
    end

    it "日本語キーワードの重複でConfigErrorを発生" do
      Dir.mktmpdir do |dir|
        # 「真」はデフォルトでtrueに割り当て済み。ifにも「真」を指定すると重複する
        path = write_config(dir, "Keyword:\n  if: 真")
        config = described_class.new(path)
        expect { config.build_keyword_map }.to raise_error(JpRuby::ConfigError, /複数の英語キーワードにマッピング/)
      end
    end
  end

  # ============================================================
  # クラス宣言キーワードのビルド
  # ============================================================
  describe "#build_class_declaration_keywords" do
    it "デフォルトでクラスとモジュールを含む" do
      config = described_class.new(nil)
      keyword_map = config.build_keyword_map
      decl_keywords = config.build_class_declaration_keywords(keyword_map)

      expect(decl_keywords).to include("クラス")
      expect(decl_keywords).to include("モジュール")
    end

    it "classがオーバーライドされた場合、新しいキーワードを含む" do
      Dir.mktmpdir do |dir|
        path = write_config(dir, "Keyword:\n  class: 組")
        config = described_class.new(path)
        keyword_map = config.build_keyword_map
        decl_keywords = config.build_class_declaration_keywords(keyword_map)

        expect(decl_keywords).to include("組")
        expect(decl_keywords).not_to include("クラス")
      end
    end
  end

  # ============================================================
  # ランタイムマップのビルド
  # ============================================================
  describe "#build_runtime_map" do
    it "オーバーライドなしでデフォルトエイリアスを返す" do
      config = described_class.new(nil)
      runtime_map = config.build_runtime_map

      expect(runtime_map["Array"]["それぞれ"]).to eq("each")
      expect(runtime_map["Kernel"]["表示"]).to eq("puts")
    end

    it "ランタイムエイリアスの上書きが正しく適用される" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Array:
            each: それぞれの要素
        YAML
        path = write_config(dir, yaml)
        config = described_class.new(path)
        runtime_map = config.build_runtime_map

        # 新しいエイリアスが追加される
        expect(runtime_map["Array"]["それぞれの要素"]).to eq("each")
        # 元のエイリアスは消える
        expect(runtime_map["Array"]["それぞれ"]).to be_nil
      end
    end

    it "デフォルトのエイリアスは他のクラスに影響しない" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Array:
            each: 配列それぞれ
        YAML
        path = write_config(dir, yaml)
        config = described_class.new(path)
        runtime_map = config.build_runtime_map

        # Hash の each は変わらない
        expect(runtime_map["Hash"]["それぞれ"]).to eq("each")
      end
    end
  end

  # ============================================================
  # 全セクションのバリデーション
  # ============================================================
  describe "ランタイムクラスの受け入れ" do
    %w[Array Hash String Integer Float Object Kernel].each do |class_name|
      it "デフォルトクラス #{class_name} が有効" do
        Dir.mktmpdir do |dir|
          path = write_config(dir, "#{class_name}:\n  to_s: 文字列化")
          config = described_class.new(path)
          expect(config.runtime_overrides).to have_key(class_name)
        end
      end
    end

    %w[File Range Regexp Enumerable Comparable].each do |class_name|
      it "デフォルト外クラス #{class_name} も動的に受け入れられる" do
        Dir.mktmpdir do |dir|
          path = write_config(dir, "#{class_name}:\n  to_s: 文字列化")
          config = described_class.new(path)
          expect(config.runtime_overrides).to have_key(class_name)
        end
      end
    end
  end

  # ============================================================
  # E2E: 設定を適用してトランスパイル
  # ============================================================
  describe "E2E: カスタムキーワードでトランスパイル" do
    it "カスタムキーワードでトランスパイルできる" do
      Dir.mktmpdir do |dir|
        config_path = write_config(dir, "Keyword:\n  class: 組\n  def: メソッド定義\n  end: 以上")
        config = described_class.new(config_path)

        keyword_map = config.build_keyword_map
        class_declaration_keywords = config.build_class_declaration_keywords(keyword_map)

        source = "組 犬\n  メソッド定義 吠える\n    表示 \"ワン\"\n  以上\n以上"
        result = JpRuby::Transpiler.new(source,
                                        keyword_map: keyword_map,
                                        class_declaration_keywords: class_declaration_keywords).transpile

        expect(result).to include("class C犬")
        expect(result).to include("def 吠える")
        expect(result).to include("end")
      end
    end

    it "デフォルトキーワードは上書き後に無効になる" do
      Dir.mktmpdir do |dir|
        config_path = write_config(dir, "Keyword:\n  class: 組")
        config = described_class.new(config_path)

        keyword_map = config.build_keyword_map
        class_declaration_keywords = config.build_class_declaration_keywords(keyword_map)

        # 「クラス」はもう変換されない
        source = "クラス テスト\n終わり"
        result = JpRuby::Transpiler.new(source,
                                        keyword_map: keyword_map,
                                        class_declaration_keywords: class_declaration_keywords).transpile

        expect(result).not_to include("class")
        expect(result).to include("クラス")
      end
    end

    it "デフォルト外クラス（Range）のエイリアスが動作する" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Range:
            to_a: 配列化
        YAML
        config_path = write_config(dir, yaml)
        config = described_class.new(config_path)

        JpRuby::Runtime.load!(config.build_runtime_map)

        expect((1..3).配列化).to eq([1, 2, 3])
      end
    end

    it "モジュール（Enumerable）のエイリアスが動作する" do
      Dir.mktmpdir do |dir|
        yaml = <<~YAML
          Enumerable:
            min: 最小
        YAML
        config_path = write_config(dir, yaml)
        config = described_class.new(config_path)

        JpRuby::Runtime.load!(config.build_runtime_map)

        expect([3, 1, 2].最小).to eq(1)
      end
    end
  end
end

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

  describe "execution" do
    it "executes a hello world program" do
      output = run_jrb('表示 "こんにちは"')
      expect(output).to eq("こんにちは\n")
    end

    it "executes arithmetic" do
      output = run_jrb("表示 1 + 2")
      expect(output).to eq("3\n")
    end

    it "executes if/else" do
      source = <<~JRB
        もし 真
          表示 "はい"
        でなければ
          表示 "いいえ"
        終わり
      JRB
      output = run_jrb(source)
      expect(output).to eq("はい\n")
    end

    it "executes class definitions" do
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
      output = run_jrb(source)
      expect(output).to eq("こんにちは\n")
    end
  end

  describe "--dump option" do
    it "outputs transpiled Ruby code" do
      output = run_jrb('表示 "テスト"', dump: true)
      expect(output.strip).to eq('puts "テスト"')
    end
  end

  describe "error handling" do
    it "raises TranspileError for syntax errors" do
      expect {
        run_jrb("定義\n終わり")
      }.to raise_error(JpRuby::TranspileError)
    end
  end
end

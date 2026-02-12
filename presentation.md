---
marp: true
theme: default
paginate: true
header: "jp-ruby - 日本語でRubyを書こう"
style: |
  section {
    font-family: 'Hiragino Sans', 'Noto Sans JP', sans-serif;
  }
  code, pre {
    font-family: 'JetBrains Mono', 'Menlo', monospace;
  }
  section.title {
    text-align: center;
    justify-content: center;
  }
  section.title h1 {
    font-size: 2.5em;
  }
  section.title p {
    font-size: 1.2em;
    color: #666;
  }
  section.end {
    text-align: center;
    justify-content: center;
  }
  table {
    font-size: 0.85em;
  }
---

<!-- _class: title -->
<!-- _header: "" -->
<!-- _paginate: false -->

# 日本語でRubyを書こう

## jp-ruby

---

# 自己紹介

<!-- ここに自己紹介を記載してください -->

- 名前:
- 所属:
- GitHub:

---

# モチベーション

**Rubyは日本語と相性が良い**

- Rubyは日本発のプログラミング言語
- 変数名やメソッド名にはすでに日本語が使える
- しかし、キーワード（`class`, `def`, `if`...）は英語のまま

**もし、キーワードまで日本語で書けたら？**

- プログラミング教育での活用
- 「コードが読める」体験の提供
- 純粋に面白い

---

# jp-ruby とは

`.jrb` ファイルに日本語キーワードでRubyを書き、実行するトランスパイラ

```
$ jp-ruby hello.jrb    # 実行
$ jp-ruby --dump hello.jrb  # 変換結果を表示
```

**特徴**

- 標準ライブラリのみで動作（外部gem不要）
- Ruby 3.2+ 対応
- 文字列・コメント内は変換しない
- 行番号を保持したエラー表示

---

# Hello, World!

```ruby
表示 "こんにちは、世界！"
```

変換結果:

```ruby
puts "こんにちは、世界！"
```

たった1行、でもキーワードが日本語になるだけで印象が変わる

---

# クラスと継承

```ruby
クラス 動物
  定義 初期化(名前)
    @名前 = 名前
  終わり

  定義 自己紹介
    表示 "私は#{@名前}です。"
  終わり
終わり

クラス 犬 < 動物
  定義 吠える
    表示 "#{@名前}: ワンワン！"
  終わり
終わり

ポチ = 犬.新規("ポチ")
ポチ.自己紹介    #=> 私はポチです。
ポチ.吠える      #=> ポチ: ワンワン！
```

---

# FizzBuzz

```ruby
定義 フィズバズ(数)
  もし 数 % 15 == 0
    "フィズバズ"
  そうでなければ 数 % 3 == 0
    "フィズ"
  そうでなければ 数 % 5 == 0
    "バズ"
  でなければ
    数.文字列変換
  終わり
終わり

1.まで上(100) する |i|
  表示 フィズバズ(i)
終わり
```

制御構文もメソッドも、すべて日本語で記述可能

---

# キーワードマッピング（抜粋）

| カテゴリ | 日本語 | Ruby |
|:---------|:-------|:-----|
| 構造 | `クラス` / `モジュール` / `定義` / `終わり` | `class` / `module` / `def` / `end` |
| 制御 | `もし` / `そうでなければ` / `でなければ` | `if` / `elsif` / `else` |
| ループ | `繰り返す` / `まで` / `する` | `while` / `until` / `do` |
| リテラル | `真` / `偽` / `無` | `true` / `false` / `nil` |
| 例外 | `始まり` / `救済` / `確保` / `発生` | `begin` / `rescue` / `ensure` / `raise` |
| フロー | `戻す` / `次へ` / `中断` / `譲る` | `return` / `next` / `break` / `yield` |

全50種以上のキーワードに対応

---

# アーキテクチャ

```
                    jp-ruby の処理フロー

  ┌──────────┐     ┌───────────┐     ┌────────────┐     ┌────────┐
  │ .jrb     │────>│ Tokenizer │────>│ Transpiler │────>│ Runner │
  │ ソース   │     │           │     │            │     │ (eval) │
  └──────────┘     └───────────┘     └────────────┘     └────────┘
                        │                  │                  │
                   StringScanner      2パス変換         Runtime.load!
                   状態機械            キーワード置換    alias_method
                   Unicode対応         クラス名補正     日本語メソッド
```

**パーサーは書かない** -- トークナイザ + 単語置換 という割り切った設計

---

# Tokenizer

`StringScanner` ベースの状態機械で、コンテキストを識別

```ruby
WORD_PATTERN = /[\p{L}_][\p{L}\p{N}_]*[?!]?/
```

**10種類のステート**

`code` → `double_string` → `single_string` → `comment` → `multi_comment` → `regex` → `heredoc` → `interpolation` → `percent_literal` → `backtick`

**なぜ必要か？**

- 文字列内の日本語はキーワードとして変換してはいけない
- `"もしかしてバグ？"` の `もし` を `if` に変えたら壊れる
- `#{}` 内はコードなので変換が必要

---

# Transpiler -- 2パス方式

**Pass 1: クラス名の収集**

```ruby
クラス 犬 < 動物   # → "犬", "動物" を収集
```

**Pass 2: トークン単位の置換**

```ruby
def replace_word(word, class_names)
  if class_names.include?(word)
    "C#{word}"              # クラス名にプレフィックス
  elsif (english = @keyword_map[word])
    english                 # キーワードを英語に
  else
    word                    # そのまま
  end
end
```

ワード単位のハッシュルックアップ -- シンプルだが確実

---

# クラス名プレフィックスの工夫

**問題**: Rubyの定数は大文字で始まる必要がある

```ruby
クラス 犬     # → class 犬 はエラー！（定数ではない）
```

**解決**: 日本語クラス名に `C` プレフィックスを自動付与

```ruby
クラス 犬 < 動物
  # ↓ トランスパイル後
class C犬 < C動物
```

- `A-Z` で始まる名前はそのまま（`StandardError` 等）
- クラス宣言で収集した名前のみ対象 → 変数は変換しない

---

# Runtime -- 日本語メソッド

`alias_method` で組み込みクラスに日本語メソッドを注入

| クラス | 日本語 → 英語（一部抜粋） |
|:-------|:--------------------------|
| Array | `それぞれ`→`each`, `変換`→`map`, `選択`→`select` |
| String | `長さ`→`length`, `分割`→`split`, `大文字`→`upcase` |
| Integer | `回`→`times`, `まで上`→`upto`, `偶数?`→`even?` |
| Hash | `鍵一覧`→`keys`, `値一覧`→`values`, `結合`→`merge` |
| Kernel | `表示`→`puts`, `出力`→`print`, `取得`→`gets` |

```ruby
数列 = [1, 2, 3, 4, 5]
二倍 = 数列.変換 { それ * 2 }   #=> [2, 4, 6, 8, 10]
```

---

# 設定システム -- .jp-ruby.yml

キーワードやメソッド名をプロジェクト単位でカスタマイズ可能

```yaml
# キーワードの上書き
Keyword:
  class: 組
  def: メソッド定義
  end: 以上
  puts: 印字

# ランタイムエイリアスの上書き
Array:
  each: それぞれの要素
  map: 写像
```

**設定ファイルの探索順序**

1. `--config` で明示的に指定
2. 入力ファイルと同じディレクトリ
3. カレントディレクトリ
4. ホームディレクトリ

---

# CLIの使い方

```bash
# ファイルを実行
$ jp-ruby examples/hello_world.jrb

# ワンライナー実行
$ jp-ruby -e '表示 "こんにちは！"'

# トランスパイル結果の確認（デバッグ用）
$ jp-ruby --dump examples/animal_classes.jrb

# カスタム設定を指定して実行
$ jp-ruby --config .jp-ruby.yml examples/fizzbuzz.jrb
```

```
使い方: jp-ruby [オプション] <ファイル.jrb>
    --dump       変換されたRubyコードを表示する
    -e CODE      コマンドラインからjp-rubyコードを実行する
    --config FILE  カスタムキーワード設定ファイルを指定する
    -v, --version  バージョンを表示する
    -h, --help     ヘルプを表示する
```

---

# 技術的こだわり

**行番号の保持**

- キーワード置換は行構造を変えない → エラー行番号がそのまま使える
- `eval(ruby_code, TOPLEVEL_BINDING, @filename, 1)`

**文字列・コメントの保護**

- 状態機械により文字列内のキーワードは変換しない
- `"もしかして"` → そのまま `"もしかして"`

**補間内の変換**

- `"結果は#{もし x > 0 そして 'はい' でなければ 'いいえ' 終わり}"` も正しく変換

**正規表現 vs 除算の判定**

- `/` の前のトークンを見て正規表現か除算かを判定
- 日本語キーワード後の `/` も正規表現として認識

---

# クイックソートで見る表現力

```ruby
定義 素早いソート(配列)
  もし 配列.長さ <= 1
    戻す 配列
  終わり

  基準 = 配列[配列.長さ / 2]
  小さい配列 = []
  大きい配列 = []

  配列.それぞれ する |要素|
    もし 要素 < 基準
      小さい配列 << 要素
    そうでなければ 要素 > 基準
      大きい配列 << 要素
    終わり
  終わり

  素早いソート(小さい配列) + [基準] + 素早いソート(大きい配列)
終わり
```

---

# まとめ

**jp-ruby の設計思想**

- パーサーを書かず、トークナイザ + 単語置換で実現
- 状態機械で文字列・コメントを正確に保護
- `alias_method` でメソッド名も日本語化
- 設定ファイルでカスタマイズ可能

**技術スタック**

- 標準ライブラリのみ（`StringScanner`, `OptionParser`）
- RSpecによるテスト
- gem として配布可能

GitHub: **github.com/jp-ruby/jp-ruby**

---

<!-- _class: end -->
<!-- _header: "" -->

# ご清聴ありがとうございました

jp-ruby で日本語プログラミングを体験してみてください

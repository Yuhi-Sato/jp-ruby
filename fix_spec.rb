content = File.read("/Users/satouyuhi/jp-ruby/spec/jp_ruby/tokenizer_spec.rb")

# Fix "preserves whitespace" test
content.sub!(
  %{tokens = tokenize("クラス  犬")\n      expect(token_values(tokens.dup.clear || tokenize("クラス  犬")))},
  %{expect(token_values("クラス  犬"))}
)

# Fix "handles operators" test
content.sub!(
  %{tokens = tokenize("a + b")\n      expect(token_values(tokens.dup.clear || tokenize("a + b")))},
  %{expect(token_values("a + b"))}
)

# Fix "preserves newlines" test
content.sub!(
  %{result = token_values(tokenize(source)).join},
  %{result = token_values(source).join}
)

File.write("/Users/satouyuhi/jp-ruby/spec/jp_ruby/tokenizer_spec.rb", content)
puts "Fixed!"

# frozen_string_literal: true

module JpRuby
  module Runtime
    def self.load!
      # Kernel methods (available everywhere)
      ::Kernel.module_eval do
        alias_method :表示, :puts
        alias_method :出力, :print
        alias_method :検査, :p
        alias_method :取得, :gets
      end

      # Array methods
      ::Array.class_eval do
        alias_method :それぞれ, :each
        alias_method :変換, :map
        alias_method :選択, :select
        alias_method :除外, :reject
        alias_method :畳み込み, :reduce
        alias_method :並べ替え, :sort
        alias_method :逆順, :reverse
        alias_method :平坦化, :flatten
        alias_method :一意, :uniq
        alias_method :含む?, :include?
        alias_method :追加, :push
        alias_method :長さ, :length
        alias_method :大きさ, :size
        alias_method :最初, :first
        alias_method :最後, :last
        alias_method :空?, :empty?
        alias_method :結合, :join
        alias_method :個数, :count
      end

      # Hash methods
      ::Hash.class_eval do
        alias_method :それぞれ, :each
        alias_method :鍵一覧, :keys
        alias_method :値一覧, :values
        alias_method :長さ, :length
        alias_method :含む?, :include?
        alias_method :空?, :empty?
        alias_method :結合, :merge
        alias_method :削除, :delete
      end

      # String methods
      ::String.class_eval do
        alias_method :長さ, :length
        alias_method :大きさ, :size
        alias_method :分割, :split
        alias_method :含む?, :include?
        alias_method :置換, :gsub
        alias_method :大文字, :upcase
        alias_method :小文字, :downcase
        alias_method :除去, :strip
        alias_method :空?, :empty?
        alias_method :逆順, :reverse
        alias_method :文字列変換, :to_s
        alias_method :整数変換, :to_i
        alias_method :小数変換, :to_f
      end

      # Integer methods
      ::Integer.class_eval do
        alias_method :回, :times
        alias_method :偶数?, :even?
        alias_method :奇数?, :odd?
        alias_method :文字列変換, :to_s
        alias_method :小数変換, :to_f
        alias_method :まで上, :upto
        alias_method :まで下, :downto
        alias_method :絶対値, :abs
      end

      # Float methods
      ::Float.class_eval do
        alias_method :整数変換, :to_i
        alias_method :文字列変換, :to_s
        alias_method :切り上げ, :ceil
        alias_method :切り捨て, :floor
        alias_method :四捨五入, :round
        alias_method :絶対値, :abs
      end

      # Object methods (available on all objects)
      ::Object.class_eval do
        alias_method :凍結, :freeze
        alias_method :凍結済み?, :frozen?
        alias_method :複製, :dup
        alias_method :は?, :is_a?
        alias_method :応答する?, :respond_to?
      end
    end
  end
end

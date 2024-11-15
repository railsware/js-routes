# typed: strict

module JsRoutes
  module Utils
    extend T::Sig
    sig {returns(T.untyped)}
    def self.shakapacker
      if defined?(::Shakapacker)
        ::Shakapacker
      elsif defined?(::Webpacker)
        ::Webpacker
      else
        nil
      end
    end
  end

end

module JsRoutes
  module Utils
    extend T::Sig
    sig {returns(T.untyped)}
    def self.shakapacker
      if defined?(Shakapacker)
        Shakapacker
      elsif defined?(Webpacker)
        Webpacker
      end
    end
  end

end

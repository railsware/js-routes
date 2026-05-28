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

    sig { returns(T.untyped) }
    def self.deprecator
      if defined?(Rails) && Rails.respond_to?(:deprecator)
        Rails.deprecator
      else
        ActiveSupport::Deprecation
      end
    end

    sig { returns(Gem::Version) }
    def self.rails_version
      Gem::Version.new(Rails.version)
    end
  end

end

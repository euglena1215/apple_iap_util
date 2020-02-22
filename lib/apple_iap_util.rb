require "apple_iap_util/version"

module AppleIapUtil
  extend ActiveSupport::Concern

  class_methods do
    def configure(&block)
      block.call(config)
    end

    def config
      @config ||= Config.new(shared_password: nil)
    end
  end
end

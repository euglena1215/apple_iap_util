module AppleIapUtil
  class GetLatestReceiptService
    class InvalidApiEnvError < StandardError; end
    class InvalidRequestError < StandardError; end
    class InternalServerError < StandardError; end

    PRODUCTION_URL = "https://buy.itunes.apple.com"
    SANDBOX_URL = "https://sandbox.itunes.apple.com"

    def initialize
      @client = {}
    end

    def perform!(receipt_data:)
      body = retry_with_env do |env|
        client(env).post('/verifyReceipt',
          {
            "receipt-data" => receipt_data,
            "password" => password || "",
          }.to_json
        )
      end

      AppleIapUtil::Receipt.new(body)
    end

    private

    def retry_with_env
      api_env = if Rails.env.production?
        :production
      else
        :sandbox
      end

      Retryable.retryable(tries: 3, on: [InvalidApiEnvError, InternalServerError, Faraday::TimeoutError, Faraday::ConnectionFailed]) do
        res = yield api_env
        body = JSON.parse(res.body)

        # See https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html
        case body["status"]
        when 0, 21006
          # do noting

          # 0     => success
          # 21006 => This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
          #          Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.
        when 21000
          raise InvalidRequestError.new("The App Store could not read the JSON object you provided.")
        when 21002
          raise InvalidRequestError.new("The data in the receipt-data property was malformed or missing.")
        when 21003
          raise InvalidRequestError.new("The receipt could not be authenticated.")
        when 21004
          raise InvalidRequestError.new("The shared secret you provided does not match the shared secret on file for your account.")
        when 21005
          raise InternalServerError.new("The receipt server is not currently available.")
        when 21007
          api_env = :sandbox
          raise InvalidApiEnvError
        when 21008
          api_env = :production
          raise InvalidApiEnvError
        when 21010
          raise InvalidRequestError.new("This receipt could not be authorized. Treat this the same as if a purchase was never made.")
        when 21100..21199
          raise InternalServerError.new("Internal data access error.")
        end

        body
      end
    end

    def client(env)
      return @client[env] if @client[env]

      url = case env
      when :sandbox
        SANDBOX_URL
      when :production
        PRODUCTION_URL
      end

      @client[env] = Faraday.new(url: url)
    end

    def password
      AppleIapUtil.config.shared_password
    end
  end
end

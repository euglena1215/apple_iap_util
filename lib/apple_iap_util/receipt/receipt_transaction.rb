module AppleIapUtil
  class Receipt
    class ReceiptTransaction
      def initialize(original_json, bundle_id)
        @original_json = original_json
        @bundle_id = bundle_id
      end

      def bundle_id
        @bundle_id
      end

      def product_id
        @original_json["product_id"]
      end

      def transaction_id
        @original_json["transaction_id"]
      end

      def expired_at
        @original_json["expires_date_ms"] ? Time.zone.at(@original_json["expires_date_ms"].to_i / 1000) : nil
      end

      def canceled_at
        @original_json["cancellation_date"] ? Time.zone.parse(@original_json["cancellation_date"]) : nil
      end

      def trial?
        @original_json["is_trial_period"].to_b
      end

      def purchased_at
        @original_json["purchase_date_ms"] ? Time.zone.at(@original_json["purchase_date_ms"].to_i / 1000) : nil
      end
    end
  end
end

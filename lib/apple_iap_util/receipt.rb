module AppleIapUtil
  class Receipt
    def initialize(original_json)
      @original_json = original_json

      # If the same transation exists `in_app` and `latest_receipt_info`, we prioritize `latest_receipt_info`.
      @transactions = (original_json["receipt"]["in_app"] + original_json["latest_receipt_info"]).map do |transaction|
        rt = ReceiptTransaction.new(transaction, bundle_id)
        [rt.transaction_id, rt]
      end.to_h
    end

    def find(transaction_id)
      @transactions[transaction_id]
    end

    def purchase_history_exist?
      @original_json["latest_receipt_info"].present?
    end

    def bundle_id
      @original_json["receipt"]["bundle_id"]
    end

    def latest_receipt_data
      @original_json["latest_receipt"]
    end

    def latest_expired_at(product_id:)
      receipt_transactions
        .reject { |rt| rt.canceled_at.present? }
        .select { |rt| rt.product_id == product_id }
        .map(&:expired_at).max
    end

    def transaction_ids
      @transactions.keys
    end

    def receipt_transactions
      @transactions.values
    end
  end
end

module AppleIapUtil
  class ValidateAppleReceiptService
    # @param receipt [AppleIapUtil::Receipt]
    # @param transaction_id [String]
    # @param available_bundle_ids [String]
    # @param available_product_ids [String]
    # @param transaction_already_used_logic [Proc]
    # @return [Boolean]
    def self.valid?(receipt:, transaction_id:, available_bundle_ids:, available_product_ids:, transaction_already_used_logic:)
      return false unless receipt.purchase_history_exist?
      return false unless receipt.bundle_id.in?(available_bundle_ids)
      return false unless receipt.find(transaction_id).product_id.in?(available_product_ids)
      return false if transaction_already_used_logic(transaction_id)
      expired_at = receipt.find(transaction_id).expired_at
      return false unless expired_at && expired_at > Time.current

      true
    end
  end
end

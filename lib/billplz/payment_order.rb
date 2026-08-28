module Billplz
  # V5. bank_code is the recipient bank's SWIFT code (MBBEMYKL, CIBBMYKL, ...).
  # In sandbox, only DUMMYBANKVERIFIED succeeds.
  #
  # The API documents create and get only — there is no index.
  class PaymentOrder < Model
    self.api_version = 'v5'
    self.resource    = 'payment_orders'

    # Optional payload: :email, :notification, :recipient_notification, :reference_id
    def create
      requires!(@payload, :payment_order_collection_id, :bank_code, :bank_account_number, :name, :description, :total)
      request(:post, sign(@payload, :payment_order_collection_id, :bank_account_number, :total))
    end

    def get
      requires!(@payload, :payment_order_id)
      request(:get, nil, path: @payload[:payment_order_id], query: signed_query(:payment_order_id))
    end
  end
end

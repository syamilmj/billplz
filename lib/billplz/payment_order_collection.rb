module Billplz
  # V5. Payment orders disburse funds out, and like bills they live inside a
  # collection. Every V5 request is signed with an epoch and a checksum; both
  # are added for you from Billplz.configuration.x_signature_key.
  class PaymentOrderCollection < Model
    self.api_version = 'v5'
    self.resource    = 'payment_order_collections'

    # Optional payload: :callback_url
    def create
      requires!(@payload, :title)
      request(:post, sign(@payload, :title, :callback_url))
    end

    def get
      requires!(@payload, :payment_order_collection_id)
      request(:get, nil,
        path: @payload[:payment_order_collection_id],
        query: signed_query(:payment_order_collection_id))
    end
  end
end

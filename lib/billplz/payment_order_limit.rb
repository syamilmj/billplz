module Billplz
  # V5. Funds available for disbursement, in the smallest currency unit.
  #
  # Rate limited well below the general limit: 3 requests per 10 minutes in
  # production, 1 per 10 seconds in sandbox.
  class PaymentOrderLimit < Model
    self.api_version = 'v5'
    self.resource    = 'payment_order_limit'

    def get
      request(:get, nil, query: signed_query)
    end
  end
end

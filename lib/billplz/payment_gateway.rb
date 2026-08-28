module Billplz
  # Every payment gateway code with its active flag and category. Billplz asks
  # that this be pulled hourly, not per request.
  class PaymentGateway < Model
    self.api_version = 'v4'
    self.resource    = 'payment_gateways'

    def index
      request(:get, nil)
    end
  end
end

module Billplz
  # FPX bank codes for Direct Payment Gateway (pass one as reference_1 with
  # reference_1_label "Bank Code"). Billplz asks that this be pulled hourly,
  # not per request. v3 only — v4 supersedes it with PaymentGateway.
  class FpxBank < Model
    self.api_version = 'v3'
    self.resource    = 'fpx_banks'

    def index
      request(:get, nil)
    end
  end
end

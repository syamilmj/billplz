module Billplz
  # Callback delivery standing, 0.0 (best) to 10.0 (worst). Degrades by 1 per
  # failed callback attempt and resets daily at 17:00.
  class WebhookRank < Model
    self.api_version = 'v4'
    self.resource    = 'webhook_rank'

    def get
      request(:get, nil)
    end
  end
end

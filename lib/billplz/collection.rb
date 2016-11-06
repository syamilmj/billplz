module Billplz
  class Collection < Model
    self.api_url = 'https://www.billplz.com/api/v3/collections'

    def create
      requires!(@payload, :title)
      request(:post, @payload)
    end
  end
end

module Billplz
  # Defaults to v3. Pass version: 'v4' for redirect_uri and two-recipient
  # split rules. Photo upload is not supported — it is a multipart field.
  class OpenCollection < Model
    self.api_version = 'v3'
    self.resource    = 'open_collections'

    def create
      requires!(@payload, :title, :description)
      requires!(@payload, :amount) unless @payload[:fixed_amount] == false

      request(:post, @payload)
    end

    def get
      requires!(@payload, :collection_id)
      request(:get, nil, path: @payload[:collection_id])
    end

    # Optional payload: :page, :status (active or inactive)
    def index
      request(:get, nil, query: slice(:page, :status))
    end
  end
end

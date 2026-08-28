module Billplz
  # Defaults to v3. Pass version: 'v4' for two-recipient split rules
  # (split_payments[][stack_order]) instead of v3's single split_payment:
  #
  #   Billplz::Collection.new({ title: 'x', split_payments: [...] }, version: 'v4')
  #
  # Logo upload is not supported — it is a multipart field, and v4 dropped it.
  class Collection < Model
    self.api_version = 'v3'
    self.resource    = 'collections'

    def create
      requires!(@payload, :title)
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

    def activate
      requires!(@payload, :collection_id)
      request(:post, nil, path: "#{@payload[:collection_id]}/activate", version: 'v3')
    end

    def deactivate
      requires!(@payload, :collection_id)
      request(:post, nil, path: "#{@payload[:collection_id]}/deactivate", version: 'v3')
    end

    def payment_methods
      requires!(@payload, :collection_id)
      request(:get, nil, path: "#{@payload[:collection_id]}/payment_methods", version: 'v3')
    end

    # Enables exactly the codes given and disables every other one.
    #
    #   Collection.new(collection_id: 'x', payment_methods: %w[fpx paypal]).update_payment_methods
    def update_payment_methods
      requires!(@payload, :collection_id, :payment_methods)

      codes = Array(@payload[:payment_methods]).map { |method| method.is_a?(Hash) ? method : { code: method } }
      request(:put, { payment_methods: codes }, path: "#{@payload[:collection_id]}/payment_methods", version: 'v3')
    end

    # Customer receipt delivery is v4 only, regardless of this instance's version.
    def customer_receipt_delivery
      receipt_delivery(:get, nil)
    end

    def activate_customer_receipt_delivery
      receipt_delivery(:post, 'activate')
    end

    def deactivate_customer_receipt_delivery
      receipt_delivery(:post, 'deactivate')
    end

    # Reverts the collection to the account-wide receipt setting.
    def global_customer_receipt_delivery
      receipt_delivery(:post, 'global')
    end

    private

    def receipt_delivery(method, action)
      requires!(@payload, :collection_id)

      path = "#{@payload[:collection_id]}/customer_receipt_delivery"
      path = "#{path}/#{action}" if action

      request(method, nil, path: path, version: 'v4')
    end
  end
end

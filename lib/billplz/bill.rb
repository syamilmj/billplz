module Billplz
  class Bill < Model
    self.api_version = 'v3'
    self.resource    = 'bills'

    def create
      requires!(@payload, :collection_id, :name, :amount, :callback_url, :description)
      requires_one_of!(@payload, :email, :mobile)
      request(:post, @payload)
    end

    def get
      requires!(@payload, :bill_id)
      request(:get, nil, path: @payload[:bill_id])
      parsed_json if success?
    end

    # Only a bill in the `due` state can be deleted; deleting a paid bill
    # returns 422. A deleted bill reappears if the customer still pays it.
    def delete
      requires!(@payload, :bill_id)
      request(:delete, nil, path: @payload[:bill_id])
    end

    # Optional payload: :page, :status (pending, completed or failed)
    def transactions
      requires!(@payload, :bill_id)
      request(:get, nil, path: "#{@payload[:bill_id]}/transactions", query: slice(:page, :status))
    end
  end
end

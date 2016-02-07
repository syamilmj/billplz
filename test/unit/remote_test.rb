require 'test_helper'

# The following tests will send actual requests to the API
#
# It's being excluded from the :default rake task to minimise
# risk of accidentally flooding the server with tests data
class RemoteTest < Minitest::Test
  include Billplz

  def setup
    Billplz.reset
    Billplz.configuration.api_key = fixtures(:api_key)
  end

  def it_creates_a_new_collection
    collection = Collection.new({ title: 'Just a mocked test' })
    collection_response = collection.create

    assert collection_response

    collection_id = response.id

    bill = Bill.new({ collection_id: collection_id, email: 'test@example.com', name: 'Test User', amount: 200, callback_url: 'http://example.com' })
    bill_response = bill.create

    assert bill_response
  end
end
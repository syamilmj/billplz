require 'test_helper'

# The following tests will send actual requests to the API
#
# It's being excluded from the :default rake task to minimise
# risk of accidentally flooding the server with tests data
# 
# For sake of brevity, only one remote test class is created
class RemoteTest < Test::Unit::TestCase
  def setup
    Billplz.reset
    Billplz.configuration.api_key = fixtures(:api_key)
  end

  def test_creates_new_collection_and_bill_then_delete
    # create collection
    collection = Billplz::Collection.new({ title: 'Just a mocked test' })
    collection_response = collection.create

    assert collection.success?
    assert_equal("JUST A MOCKED TEST", collection.parsed_json['title'])

    collection_id = collection.parsed_json['id']

    # create bill
    bill = Billplz::Bill.new({ collection_id: collection_id, email: 'test@example.com', name: 'Test User', amount: 200, callback_url: 'http://example.com' })
    bill_response = bill.create

    assert bill.success?
    assert_equal(200, bill.parsed_json['amount'])

    bill_id = bill.parsed_json['id']

    # get bill
    bill = Billplz::Bill.new({ bill_id: bill_id })
    bill_response = bill.get

    assert bill.success?
    assert_equal(bill_id, bill.parsed_json['id'])

    # delete bill
    bill = Billplz::Bill.new({ bill_id: bill_id })
    bill.delete

    assert bill.success?

    # retrieve deleted bill
    bill = Billplz::Bill.new({ bill_id: bill_id })
    bill_response = bill.get

    assert_instance_of(Net::HTTPNotFound, bill_response)
  end
end
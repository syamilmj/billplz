require 'test_helper'

# Hits the real Billplz sandbox. Excluded from the default rake task and from
# CI; run it deliberately with `rake test:remote` and a sandbox key:
#
#   BILLPLZ_API_KEY=your-sandbox-key rake test:remote
#
# Skips itself when no key is set. Never point this at a production key.
class RemoteTest < Minitest::Test
  def setup
    WebMock.allow_net_connect!

    @api_key = ENV['BILLPLZ_API_KEY']
    skip 'Set BILLPLZ_API_KEY to a sandbox key to run the remote tests' if @api_key.nil? || @api_key.empty?

    Billplz.reset
    Billplz.configuration.api_key = @api_key
    Billplz.configuration.mode    = 'sandbox'
  end

  def teardown
    WebMock.disable_net_connect!
  end

  def test_creates_new_collection_and_bill_then_deletes_it
    collection = Billplz::Collection.new(title: 'Remote test collection')
    collection.create

    assert collection.success?, "collection create failed: #{collection.response.body}"
    collection_id = collection.parsed_json['id']

    bill = Billplz::Bill.new(
      collection_id: collection_id,
      email: 'test@example.com',
      name: 'Test User',
      amount: 200,
      callback_url: 'https://example.com/callback',
      description: 'Remote test bill'
    )
    bill.create

    assert bill.success?, "bill create failed: #{bill.response.body}"
    assert_equal 200, bill.parsed_json['amount']
    bill_id = bill.parsed_json['id']

    fetched = Billplz::Bill.new(bill_id: bill_id)
    assert_equal bill_id, fetched.get['id']

    deleted = Billplz::Bill.new(bill_id: bill_id)
    deleted.delete
    assert deleted.success?

    gone = Billplz::Bill.new(bill_id: bill_id)
    assert_nil gone.get
    assert_instance_of Net::HTTPNotFound, gone.response
  end
end

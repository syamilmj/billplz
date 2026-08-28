require 'test_helper'

# Pins the 0.1.3 public interface so it keeps working. The one deliberate
# break is Bill#create, which now also requires :description — the API has
# always required it, so those calls were already failing with 422.
class BackwardsCompatibilityTest < Minitest::Test
  def test_the_original_readme_usage_still_works
    Billplz.reset
    Billplz.configuration = { api_key: 'legacy-key' }

    stub_api(:post, "#{LIVE}/v3/collections", body: '{"id":"bnck5esg","title":"MY AWESOME COLLECTION"}')

    collection = Billplz::Collection.new({ title: 'My awesome collection' })
    collection.create

    assert collection.success?
    assert_equal 'bnck5esg', collection.parsed_json['id']

    stub_api(:post, "#{LIVE}/v3/bills", body: '{"id":"abc123","state":"due","paid":false}')

    bill = Billplz::Bill.new({
      collection_id: 'bnck5esg',
      email: 'test@example.com',
      name: 'Test User',
      amount: 200,
      callback_url: 'https://example.com/callback',
      description: 'A bill'
    })
    bill.create

    assert bill.success?
    assert_equal 'abc123', bill.parsed_json['id']

    stub_api(:get, "#{LIVE}/v3/bills/abc123", body: '{"id":"abc123","state":"due","paid":false}')

    fetched = Billplz::Bill.new({ bill_id: 'abc123' }).get

    assert_equal 'due', fetched['state']
    assert_equal false, fetched['paid']

    stub_api(:delete, "#{LIVE}/v3/bills/abc123")

    deleted = Billplz::Bill.new({ bill_id: 'abc123' })
    deleted.delete

    assert deleted.success?
  end

  def test_payload_accessor_is_still_public
    bill = Billplz::Bill.new({ bill_id: 'abc123' })

    assert_equal({ bill_id: 'abc123' }, bill.payload)

    bill.payload = { bill_id: 'xyz789' }
    assert_equal 'xyz789', bill.payload[:bill_id]
  end

  # A subclass assigning a full URL bypasses host/version construction.
  def test_a_hardcoded_class_level_api_url_still_wins
    legacy = Class.new(Billplz::Model) do
      self.api_url = 'https://www.billplz.com/api/v3/bills'
    end

    stub_api(:get, "#{LIVE}/v3/bills/abc123", body: '{"id":"abc123"}')

    instance = legacy.new
    instance.request(:get, nil, path: 'abc123')

    assert instance.success?
  end
end

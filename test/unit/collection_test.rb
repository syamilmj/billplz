require 'test_helper'

class CollectionTest < Minitest::Test
  COLLECTION = '{"id":"bnck5esg","title":"JUST A TEST","logo":{"thumb_url":null,"avatar_url":null}}'.freeze

  def test_create
    stub_api(:post, "#{LIVE}/v3/collections", body: COLLECTION)

    collection = Billplz::Collection.new(title: 'Just a test')
    collection.create

    assert collection.success?
    assert_equal 'bnck5esg', collection.parsed_json['id']
    assert_requested :post, "#{LIVE}/v3/collections",
      headers: { 'Authorization' => auth_header },
      body: { 'title' => 'Just a test' }
  end

  def test_create_requires_title
    assert_raises(ArgumentError) { Billplz::Collection.new({}).create }
  end

  # v4 nests split rules as an array with an explicit stack_order.
  def test_v4_create_encodes_split_payments_array
    stub_api(:post, "#{LIVE}/v4/collections", body: COLLECTION)

    payload = {
      title: 'Split',
      split_header: true,
      split_payments: [
        { email: 'a@example.com', fixed_cut: 100, stack_order: 0 },
        { email: 'b@example.com', variable_cut: 3, stack_order: 1 }
      ]
    }
    Billplz::Collection.new(payload, version: 'v4').create

    assert_requested :post, "#{LIVE}/v4/collections", body:
      'title=Split&split_header=true' \
      '&split_payments%5B%5D%5Bemail%5D=a%40example.com' \
      '&split_payments%5B%5D%5Bfixed_cut%5D=100' \
      '&split_payments%5B%5D%5Bstack_order%5D=0' \
      '&split_payments%5B%5D%5Bemail%5D=b%40example.com' \
      '&split_payments%5B%5D%5Bvariable_cut%5D=3' \
      '&split_payments%5B%5D%5Bstack_order%5D=1'
  end

  def test_get
    stub_api(:get, "#{LIVE}/v3/collections/bnck5esg", body: COLLECTION)

    Billplz::Collection.new(collection_id: 'bnck5esg').get

    assert_authorized :get, "#{LIVE}/v3/collections/bnck5esg"
  end

  def test_index_passes_page_and_status
    stub_api(:get, "#{LIVE}/v3/collections?page=2&status=active", body: '{"collections":[],"page":"2"}')

    Billplz::Collection.new(page: 2, status: 'active').index

    assert_requested :get, "#{LIVE}/v3/collections?page=2&status=active"
  end

  def test_index_without_arguments_sends_no_query
    stub_api(:get, "#{LIVE}/v3/collections", body: '{"collections":[]}')

    Billplz::Collection.new.index

    assert_requested :get, "#{LIVE}/v3/collections"
  end

  def test_activate_and_deactivate
    stub_api(:post, "#{LIVE}/v3/collections/bnck5esg/activate")
    stub_api(:post, "#{LIVE}/v3/collections/bnck5esg/deactivate")

    collection = Billplz::Collection.new(collection_id: 'bnck5esg')
    collection.activate
    collection.deactivate

    assert_authorized :post, "#{LIVE}/v3/collections/bnck5esg/activate"
    assert_authorized :post, "#{LIVE}/v3/collections/bnck5esg/deactivate"
  end

  def test_payment_methods_index
    stub_api(:get, "#{LIVE}/v3/collections/bnck5esg/payment_methods",
      body: '{"payment_methods":[{"code":"fpx","name":"FPX","active":true}]}')

    collection = Billplz::Collection.new(collection_id: 'bnck5esg')
    collection.payment_methods

    assert_equal 'fpx', collection.parsed_json['payment_methods'].first['code']
  end

  # The API expects a repeated payment_methods[][code] pair per enabled code.
  def test_update_payment_methods_encoding
    stub_api(:put, "#{LIVE}/v3/collections/bnck5esg/payment_methods", body: '{"payment_methods":[]}')

    Billplz::Collection.new(collection_id: 'bnck5esg', payment_methods: %w[fpx paypal]).update_payment_methods

    assert_requested :put, "#{LIVE}/v3/collections/bnck5esg/payment_methods",
      body: 'payment_methods%5B%5D%5Bcode%5D=fpx&payment_methods%5B%5D%5Bcode%5D=paypal'
  end

  # Receipt delivery only exists under v4, even from a v3 instance.
  def test_customer_receipt_delivery_uses_v4
    stub_api(:get, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery",
      body: '{"id":"bnck5esg","customer_receipt_delivery":"active"}')
    stub_api(:post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/activate")
    stub_api(:post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/deactivate")
    stub_api(:post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/global")

    collection = Billplz::Collection.new(collection_id: 'bnck5esg')
    collection.customer_receipt_delivery
    collection.activate_customer_receipt_delivery
    collection.deactivate_customer_receipt_delivery
    collection.global_customer_receipt_delivery

    assert_requested :get,  "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery"
    assert_requested :post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/activate"
    assert_requested :post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/deactivate"
    assert_requested :post, "#{LIVE}/v4/collections/bnck5esg/customer_receipt_delivery/global"
  end
end

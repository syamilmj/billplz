require 'test_helper'

# V5 signs every request with an epoch and an HMAC-SHA512 checksum over the
# values of that endpoint's documented checksum arguments, in order.
class PaymentOrderTest < Minitest::Test
  EPOCH = 1681724303

  def checksum(*values)
    OpenSSL::HMAC.hexdigest('SHA512', X_SIGNATURE_KEY, values.join)
  end

  def test_create_collection_signs_title_and_epoch
    stub_api(:post, "#{LIVE}/v5/payment_order_collections", body: '{"id":"pmocol1"}')

    Billplz::PaymentOrderCollection.new(title: 'Payroll', epoch: EPOCH).create

    assert_requested :post, "#{LIVE}/v5/payment_order_collections",
      body: hash_including('epoch' => EPOCH.to_s, 'checksum' => checksum('Payroll', EPOCH))
  end

  def test_create_collection_includes_callback_url_in_the_checksum
    stub_api(:post, "#{LIVE}/v5/payment_order_collections", body: '{"id":"pmocol1"}')

    callback = 'https://example.com/payment_orders'
    Billplz::PaymentOrderCollection.new(title: 'Payroll', callback_url: callback, epoch: EPOCH).create

    assert_requested :post, "#{LIVE}/v5/payment_order_collections",
      body: hash_including('checksum' => checksum('Payroll', callback, EPOCH))
  end

  def test_epoch_defaults_to_now
    stub_api(:post, "#{LIVE}/v5/payment_order_collections", body: '{"id":"pmocol1"}')

    before = Time.now.to_i
    Billplz::PaymentOrderCollection.new(title: 'Payroll').create

    assert_requested :post, "#{LIVE}/v5/payment_order_collections" do |request|
      epoch = URI.decode_www_form(request.body).to_h['epoch'].to_i
      epoch >= before && epoch <= Time.now.to_i
    end
  end

  def test_get_collection_signs_id_and_epoch_in_the_query
    query = { epoch: EPOCH, checksum: checksum('pmocol1', EPOCH) }
    stub_api(:get, "#{LIVE}/v5/payment_order_collections/pmocol1?#{URI.encode_www_form(query)}",
      body: '{"id":"pmocol1","status":"active"}')

    Billplz::PaymentOrderCollection.new(payment_order_collection_id: 'pmocol1', epoch: EPOCH).get

    assert_requested :get, "#{LIVE}/v5/payment_order_collections/pmocol1?#{URI.encode_www_form(query)}"
  end

  def test_create_payment_order_signs_collection_account_and_total
    stub_api(:post, "#{LIVE}/v5/payment_orders", body: '{"id":"pmo1","status":"processing"}')

    payload = {
      payment_order_collection_id: 'pmocol1',
      bank_code: 'MBBEMYKL',
      bank_account_number: '1234567890',
      name: 'Recipient',
      description: 'Salary',
      total: 10_000,
      epoch: EPOCH
    }
    Billplz::PaymentOrder.new(payload).create

    assert_requested :post, "#{LIVE}/v5/payment_orders",
      body: hash_including(
        'bank_code' => 'MBBEMYKL',
        'checksum'  => checksum('pmocol1', '1234567890', 10_000, EPOCH)
      )
  end

  def test_create_payment_order_requires_bank_code
    payload = { payment_order_collection_id: 'pmocol1', bank_account_number: '1',
                name: 'R', description: 'D', total: 1 }

    error = assert_raises(ArgumentError) { Billplz::PaymentOrder.new(payload).create }
    assert_match(/bank_code/, error.message)
  end

  def test_get_payment_order
    query = { epoch: EPOCH, checksum: checksum('pmo1', EPOCH) }
    stub_api(:get, "#{LIVE}/v5/payment_orders/pmo1?#{URI.encode_www_form(query)}", body: '{"id":"pmo1"}')

    Billplz::PaymentOrder.new(payment_order_id: 'pmo1', epoch: EPOCH).get

    assert_requested :get, "#{LIVE}/v5/payment_orders/pmo1?#{URI.encode_www_form(query)}"
  end

  def test_payment_order_limit_signs_epoch_alone
    query = { epoch: EPOCH, checksum: checksum(EPOCH) }
    stub_api(:get, "#{LIVE}/v5/payment_order_limit?#{URI.encode_www_form(query)}", body: '{"total":"9600"}')

    limit = Billplz::PaymentOrderLimit.new(epoch: EPOCH)
    limit.get

    assert_equal '9600', limit.parsed_json['total']
    assert_requested :get, "#{LIVE}/v5/payment_order_limit?#{URI.encode_www_form(query)}"
  end

  def test_sandbox_mode_routes_v5_to_the_sandbox_host
    Billplz.configuration.mode = 'sandbox'
    stub_api(:post, "#{SANDBOX}/v5/payment_order_collections", body: '{"id":"pmocol1"}')

    Billplz::PaymentOrderCollection.new(title: 'Payroll', epoch: EPOCH).create

    assert_requested :post, "#{SANDBOX}/v5/payment_order_collections"
  end
end

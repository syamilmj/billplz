require 'test_helper'

class ModelTest < Minitest::Test
  def test_encode_form_flat_params
    assert_equal 'title=Hello+world&amount=200', Billplz.encode_form(title: 'Hello world', amount: 200)
  end

  def test_encode_form_drops_nil_values
    assert_equal 'title=Hello', Billplz.encode_form(title: 'Hello', due_at: nil)
  end

  def test_encode_form_nests_hashes
    encoded = Billplz.encode_form(split_payment: { email: 'a@example.com', fixed_cut: 100 })

    assert_equal 'split_payment%5Bemail%5D=a%40example.com&split_payment%5Bfixed_cut%5D=100', encoded
  end

  def test_encode_form_repeats_arrays_of_hashes
    encoded = Billplz.encode_form(payment_methods: [{ code: 'fpx' }, { code: 'paypal' }])

    assert_equal 'payment_methods%5B%5D%5Bcode%5D=fpx&payment_methods%5B%5D%5Bcode%5D=paypal', encoded
  end

  def test_encode_form_repeats_arrays_of_scalars
    assert_equal 'codes%5B%5D=a&codes%5B%5D=b', Billplz.encode_form(codes: %w[a b])
  end

  def test_encode_form_of_nil_is_an_empty_body
    assert_equal '', Billplz.encode_form(nil)
  end

  def test_get_rejects_a_body
    assert_raises(ArgumentError) { Billplz::Bill.new.send(:request, :get, { a: 1 }) }
  end

  def test_delete_rejects_a_body
    assert_raises(ArgumentError) { Billplz::Bill.new.send(:request, :delete, { a: 1 }) }
  end

  def test_unsupported_method_raises
    assert_raises(ArgumentError) { Billplz::Bill.new.send(:request, :head) }
  end

  def test_error_is_nil_on_success
    stub_api(:get, "#{LIVE}/v3/collections/x", body: '{"id":"x"}')

    collection = Billplz::Collection.new(collection_id: 'x')
    collection.get

    assert_nil collection.error
  end

  def test_error_is_nil_when_the_body_is_not_json
    stub_api(:get, "#{LIVE}/v3/collections/x", status: 503, body: '<html>Service Unavailable</html>')

    collection = Billplz::Collection.new(collection_id: 'x')
    collection.get

    refute collection.success?
    assert_nil collection.error
  end

  # RateLimit headers read "unlimited" when no limit is applied.
  def test_rate_limit_passes_through_non_numeric_values
    stub_request(:get, "#{LIVE}/v3/collections/x").to_return(
      status: 200, body: '{}',
      headers: { 'RateLimit-Limit' => 'unlimited', 'RateLimit-Remaining' => 'unlimited',
                 'RateLimit-Reset' => 'unlimited' }
    )

    collection = Billplz::Collection.new(collection_id: 'x')
    collection.get

    assert_equal({ limit: 'unlimited', remaining: 'unlimited', reset: 'unlimited' }, collection.rate_limit)
  end

  def test_fpx_banks
    stub_api(:get, "#{LIVE}/v3/fpx_banks", body: '{"banks":[{"name":"MB2U0227","active":true}]}')

    banks = Billplz::FpxBank.new
    banks.index

    assert_equal 'MB2U0227', banks.parsed_json['banks'].first['name']
    assert_authorized :get, "#{LIVE}/v3/fpx_banks"
  end

  def test_payment_gateways
    stub_api(:get, "#{LIVE}/v4/payment_gateways",
      body: '{"payment_gateways":[{"code":"BP-FKR01","active":true,"category":"fpx"}]}')

    gateways = Billplz::PaymentGateway.new
    gateways.index

    assert_equal 'BP-FKR01', gateways.parsed_json['payment_gateways'].first['code']
  end

  def test_webhook_rank
    stub_api(:get, "#{LIVE}/v4/webhook_rank", body: '{"rank":0.0}')

    rank = Billplz::WebhookRank.new
    rank.get

    assert_equal 0.0, rank.parsed_json['rank']
  end
end

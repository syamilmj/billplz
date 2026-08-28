require 'test_helper'

class BillTest < Minitest::Test
  BILL = '{"id":"g4jnbq","collection_id":"iyvoxe8f","paid":false,"state":"due","amount":200,' \
         '"paid_amount":0,"due_at":"2026-08-28","email":"test@example.com","mobile":null,' \
         '"name":"TEST USER","url":"https://www.billplz.com/bills/g4jnbq"}'.freeze

  def valid_payload
    {
      collection_id: 'iyvoxe8f',
      email: 'test@example.com',
      name: 'Test User',
      amount: 200,
      callback_url: 'https://example.com/callback',
      description: 'Test bill'
    }
  end

  def test_create_posts_form_encoded_payload
    stub_api(:post, "#{LIVE}/v3/bills", body: BILL)

    bill = Billplz::Bill.new(valid_payload)
    bill.create

    assert bill.success?
    assert_equal 'g4jnbq', bill.parsed_json['id']

    assert_requested :post, "#{LIVE}/v3/bills",
      headers: { 'Authorization' => auth_header, 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: { 'collection_id' => 'iyvoxe8f', 'email' => 'test@example.com', 'name' => 'Test User',
              'amount' => '200', 'callback_url' => 'https://example.com/callback',
              'description' => 'Test bill' }
  end

  def test_create_accepts_mobile_instead_of_email
    stub_api(:post, "#{LIVE}/v3/bills", body: BILL)

    payload = valid_payload
    payload.delete(:email)
    payload[:mobile] = '+60112345678'

    Billplz::Bill.new(payload).create

    assert_requested :post, "#{LIVE}/v3/bills", body: hash_including('mobile' => '+60112345678')
  end

  def test_create_requires_email_or_mobile
    payload = valid_payload
    payload.delete(:email)

    error = assert_raises(ArgumentError) { Billplz::Bill.new(payload).create }
    assert_match(/email or mobile/, error.message)
  end

  def test_create_requires_description
    payload = valid_payload
    payload.delete(:description)

    error = assert_raises(ArgumentError) { Billplz::Bill.new(payload).create }
    assert_match(/description/, error.message)
  end

  def test_get_returns_parsed_bill
    stub_api(:get, "#{LIVE}/v3/bills/g4jnbq", body: BILL)

    bill = Billplz::Bill.new(bill_id: 'g4jnbq')

    assert_equal 'due', bill.get['state']
    assert_authorized :get, "#{LIVE}/v3/bills/g4jnbq"
  end

  def test_get_returns_nil_when_not_found
    stub_api(:get, "#{LIVE}/v3/bills/nope", status: 404, body: '{"error":{"message":["Not Found"],"type":"RecordNotFound"}}')

    bill = Billplz::Bill.new(bill_id: 'nope')

    assert_nil bill.get
    refute bill.success?
    assert_equal 'RecordNotFound', bill.error['type']
  end

  # The path is built per request, so an instance is not single-use.
  def test_get_does_not_accumulate_the_id_in_the_url
    stub_api(:get, "#{LIVE}/v3/bills/g4jnbq", body: BILL)

    bill = Billplz::Bill.new(bill_id: 'g4jnbq')
    bill.get
    bill.get

    assert_requested :get, "#{LIVE}/v3/bills/g4jnbq", times: 2
  end

  def test_delete
    stub_api(:delete, "#{LIVE}/v3/bills/g4jnbq")

    bill = Billplz::Bill.new(bill_id: 'g4jnbq')
    bill.delete

    assert bill.success?
    assert_authorized :delete, "#{LIVE}/v3/bills/g4jnbq"
  end

  def test_transactions_passes_page_and_status_as_query
    stub_api(:get, "#{LIVE}/v3/bills/g4jnbq/transactions?page=2&status=completed",
      body: '{"bill_id":"g4jnbq","transactions":[],"page":"2"}')

    Billplz::Bill.new(bill_id: 'g4jnbq', page: 2, status: 'completed').transactions

    assert_requested :get, "#{LIVE}/v3/bills/g4jnbq/transactions?page=2&status=completed"
  end

  def test_sandbox_mode_routes_to_the_sandbox_host
    Billplz.configuration.mode = 'sandbox'
    stub_api(:post, "#{SANDBOX}/v3/bills", body: BILL)

    Billplz::Bill.new(valid_payload).create

    assert_requested :post, "#{SANDBOX}/v3/bills"
  end

  # Bills are created with 200, but nothing should depend on that specific code.
  def test_created_responses_count_as_success
    stub_api(:post, "#{LIVE}/v3/bills", status: 201, body: BILL)

    bill = Billplz::Bill.new(valid_payload)
    bill.create

    assert bill.success?
  end

  def test_rate_limit_headers_are_exposed
    stub_request(:get, "#{LIVE}/v3/bills/g4jnbq").to_return(
      status: 429,
      body: '{"error":{"type":"RateLimit","message":["Too many requests"]}}',
      headers: { 'Content-Type' => 'application/json', 'RateLimit-Limit' => '100',
                 'RateLimit-Remaining' => '0', 'RateLimit-Reset' => '42' }
    )

    bill = Billplz::Bill.new(bill_id: 'g4jnbq')
    bill.get

    assert bill.rate_limited?
    assert_equal({ limit: 100, remaining: 0, reset: 42 }, bill.rate_limit)
  end
end

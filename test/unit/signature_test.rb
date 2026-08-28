require 'test_helper'

# Vectors are the worked examples from the Billplz API reference.
class SignatureTest < Minitest::Test
  CALLBACK = {
    'id'            => 'zq0tm2wc',
    'collection_id' => 'yhx5t1pp',
    'paid'          => 'true',
    'state'         => 'paid',
    'amount'        => '100',
    'paid_amount'   => '100',
    'due_at'        => '2018-9-27',
    'email'         => 'tester@test.com',
    'mobile'        => '',
    'name'          => 'TESTER',
    'url'           => 'http://www.billplz-sandbox.com/bills/zq0tm2wc',
    'paid_at'       => '2018-09-27 15:15:09 +0800'
  }.freeze

  CALLBACK_SOURCE = 'amount100|collection_idyhx5t1pp|due_at2018-9-27|emailtester@test.com|' \
                    'idzq0tm2wc|mobile|nameTESTER|paid_amount100|' \
                    'paid_at2018-09-27 15:15:09 +0800|paidtrue|statepaid|' \
                    'urlhttp://www.billplz-sandbox.com/bills/zq0tm2wc'.freeze

  REDIRECT_SOURCE = 'billplzidzq0tm2wc|billplzpaid_at2018-09-27 15:15:09 +0800|billplzpaidtrue'.freeze

  def test_callback_source_string
    assert_equal CALLBACK_SOURCE, Billplz::Signature.source_string(CALLBACK)
  end

  # Rack/Rails hand the redirect over already nested under "billplz".
  def test_redirect_source_string_from_nested_params
    params = { 'billplz' => { 'id' => 'zq0tm2wc', 'paid' => 'true', 'paid_at' => '2018-09-27 15:15:09 +0800' } }

    assert_equal REDIRECT_SOURCE, Billplz::Signature.source_string(params)
  end

  # ...but a raw query string leaves the brackets in the key.
  def test_redirect_source_string_from_bracketed_keys
    params = {
      'billplz[id]'      => 'zq0tm2wc',
      'billplz[paid]'    => 'true',
      'billplz[paid_at]' => '2018-09-27 15:15:09 +0800'
    }

    assert_equal REDIRECT_SOURCE, Billplz::Signature.source_string(params)
  end

  def test_x_signature_is_excluded_from_the_source_string
    signed = CALLBACK.merge('x_signature' => 'deadbeef')

    assert_equal CALLBACK_SOURCE, Billplz::Signature.source_string(signed)
  end

  def test_nested_x_signature_is_excluded_from_the_source_string
    params = { 'billplz' => { 'id' => 'zq0tm2wc', 'paid' => 'true',
                              'paid_at' => '2018-09-27 15:15:09 +0800', 'x_signature' => 'deadbeef' } }

    assert_equal REDIRECT_SOURCE, Billplz::Signature.source_string(params)
  end

  def test_verify_accepts_a_genuine_callback
    params = CALLBACK.merge('x_signature' => Billplz::Signature.sign(CALLBACK))

    assert Billplz::Signature.verify(params)
  end

  def test_verify_accepts_a_genuine_redirect
    redirect = { 'billplz' => { 'id' => 'zq0tm2wc', 'paid' => 'true', 'paid_at' => '2018-09-27 15:15:09 +0800' } }
    redirect['billplz']['x_signature'] = Billplz::Signature.sign(redirect)

    assert Billplz::Signature.verify(redirect)
  end

  def test_verify_rejects_a_tampered_amount
    params = CALLBACK.merge('x_signature' => Billplz::Signature.sign(CALLBACK))
    params['amount'] = '1'

    refute Billplz::Signature.verify(params)
  end

  def test_verify_rejects_a_missing_signature
    refute Billplz::Signature.verify(CALLBACK)
  end

  def test_verify_rejects_a_signature_from_the_wrong_key
    params = CALLBACK.merge('x_signature' => Billplz::Signature.sign(CALLBACK, 'someone-elses-key'))

    refute Billplz::Signature.verify(params)
  end

  def test_verify_rejects_a_truncated_signature
    params = CALLBACK.merge('x_signature' => Billplz::Signature.sign(CALLBACK)[0, 10])

    refute Billplz::Signature.verify(params)
  end

  def test_sign_uses_hmac_sha256_with_the_x_signature_key
    expected = OpenSSL::HMAC.hexdigest('SHA256', X_SIGNATURE_KEY, CALLBACK_SOURCE)

    assert_equal expected, Billplz::Signature.sign(CALLBACK)
  end

  # V5 concatenates values only — no keys, no separator — and digests SHA512.
  def test_checksum_uses_hmac_sha512_over_concatenated_values
    expected = OpenSSL::HMAC.hexdigest('SHA512', X_SIGNATURE_KEY, 'My payment order title1681724303')

    assert_equal expected, Billplz::Signature.checksum(['My payment order title', 1681724303])
  end

  def test_checksum_omits_absent_optional_arguments
    with_callback = Billplz::Signature.checksum(['Title', nil, 1681724303])
    without       = Billplz::Signature.checksum(['Title', 1681724303])

    assert_equal without, with_callback
  end

  def test_signing_without_a_key_raises
    Billplz.configuration.x_signature_key = nil

    assert_raises(ArgumentError) { Billplz::Signature.sign(CALLBACK) }
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'billplz'
require 'minitest/autorun'
require 'securerandom'
require 'webmock/minitest'
require 'yaml'

class Minitest::Test
  API_KEY         = 'test-api-key'.freeze
  X_SIGNATURE_KEY = 'test-x-signature-key'.freeze

  LIVE    = 'https://www.billplz.com/api'.freeze
  SANDBOX = 'https://www.billplz-sandbox.com/api'.freeze

  def setup
    Billplz.reset
    Billplz.configuration.api_key         = API_KEY
    Billplz.configuration.x_signature_key = X_SIGNATURE_KEY
  end

  def fixtures(key)
    YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures.yml'))[key.to_s]
  end

  def auth_header
    'Basic ' + ["#{API_KEY}:"].pack('m0')
  end

  # Stubs an API call and returns the stub, so tests can assert on the request
  # that was actually made rather than only on the canned response.
  def stub_api(method, url, status: 200, body: '{}')
    stub_request(method, url).to_return(
      status: status,
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  # Every request must carry HTTP Basic auth built from the API key.
  def assert_authorized(method, url)
    assert_requested(method, url, headers: { 'Authorization' => auth_header })
  end
end

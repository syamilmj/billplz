require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @api_key = SecureRandom.uuid
    Billplz.reset
  end

  def test_version_number
    refute_nil ::Billplz::VERSION
  end

  def test_it_assigns_configuration_block
    Billplz.configure do |config|
      config.api_key = @api_key
    end

    assert_equal(@api_key, Billplz.configuration.api_key)
  end

  def test_it_reassigns_configuration_at_runtime
    Billplz.configure do |config|
      config.api_key = @api_key
    end

    new_key = SecureRandom.uuid

    Billplz.configuration.api_key = new_key

    assert_equal(new_key, Billplz.configuration.api_key)
  end

  def test_it_assigns_hash_configurations
    Billplz.configuration = { api_key: @api_key, http_timeout: 120 }

    assert_equal({ api_key: @api_key, x_signature_key: nil, http_timeout: 120, mode: 'live' }, Billplz.options)
  end

  def test_it_accepts_options_on_initialize
    config = Billplz::Configuration.new(api_key: @api_key, mode: 'sandbox')

    assert_equal(@api_key, config.api_key)
    assert config.sandbox?
  end

  def test_it_defaults_to_the_live_host
    refute Billplz.configuration.sandbox?
    assert_equal 'https://www.billplz.com/api', Billplz.configuration.host
  end

  def test_sandbox_mode_switches_the_host
    Billplz.configuration.mode = 'sandbox'

    assert Billplz.configuration.sandbox?
    assert_equal 'https://www.billplz-sandbox.com/api', Billplz.configuration.host
  end
end

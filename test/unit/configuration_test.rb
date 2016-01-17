require 'test_helper'

class ConfigurationTest < Test::Unit::TestCase
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

    assert_equal({ api_key: @api_key, http_timeout: 120, mode: 'live' }, Billplz.options)
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'billplz'
require 'test/unit'
require 'securerandom'
require 'mocha/test_unit'
require 'yaml'

class Test::Unit::TestCase
  def fixtures(key)
    fixtures = YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures.yml'))
    fixtures[key.to_s]
  end

  def assert_response(type, message = nil)
    message ||= "Expected response to be a <#{type}>, but was <#{@response.response_code}>"

    if Symbol === type
      if [:success, :missing, :redirect, :error].include?(type)
        assert @response.send("#{type}?"), message
      else
        code = Rack::Utils::SYMBOL_TO_STATUS_CODE[type]
        if code.nil?
          raise ArgumentError, "Invalid response type :#{type}"
        end
        assert_equal code, @response.response_code, message
      end
    else
      assert_equal type, @response.response_code, message
    end
  end
end

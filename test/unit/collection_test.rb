require 'test_helper'

class CollectionTest < Minitest::Test
  include Billplz

  def setup
    Billplz.reset
    Billplz.configuration.api_key = SecureRandom.uuid
  end

  def test_create
    collection = Collection.new({ title: 'Just a mocked test' })
    collection.expects(:create).returns({
      headers: {'Content-Type'=>'application/json; charset=utf-8\r\n'},
      body: "{\"id\":\"bnck5esg\",\"title\":\"JUST A MOCKED TEST\",\"logo\":{\"thumb_url\":null,\"avatar_url\":null}}",
      status: 200
    })
    assert collection.create
  end
end
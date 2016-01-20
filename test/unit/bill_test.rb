require 'test_helper'

class BillTest < Minitest::Test
  def setup
    Billplz.reset
    Billplz.configuration.api_key = SecureRandom.uuid
  end

  def test_create
    bill = Billplz::Bill.new({ collection_id: 'iyvoxe8f', email: 'test@example.com', name: 'Test User', amount: 200, callback_url: 'http://example.com' })
    bill.expects(:create).returns({
      headers: {'Content-Type'=>'application/json; charset=utf-8\r\n'},
      body: "{\"id\":\"g4jnbq\",\"collection_id\":\"iyvoxe8f\",\"paid\":false,\"state\":\"due\",\"amount\":200,\"paid_amount\":0,\"due_at\":\"2016-1-17\",\"email\":\"test@example.com\",\"mobile\":null,\"name\":\"TEST USER\",\"metadata\":{},\"url\":\"https://www.billplz.com/bills/g4jnbq\"}",
      status: 200
    })
    assert bill.create
  end

  def test_get
    bill = Billplz::Bill.new({ bill_id: 'hdyei3k' })
    bill.expects(:get).returns({
      headers: {'Content-Type'=>'application/json; charset=utf-8\r\n'},
      body: "{\"id\":\"bnck5esg\",\"title\":\"JUST A MOCKED TEST\",\"logo\":{\"thumb_url\":null,\"avatar_url\":null}}",
      status: 200
    })
    assert bill.get
  end
end
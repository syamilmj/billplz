require 'test_helper'

class OpenCollectionTest < Minitest::Test
  OPEN_COLLECTION = '{"id":"inbmmepb","title":"My Product","amount":200,"fixed_amount":true,' \
                    '"url":"https://www.billplz.com/inbmmepb"}'.freeze

  def test_create
    stub_api(:post, "#{LIVE}/v3/open_collections", body: OPEN_COLLECTION)

    collection = Billplz::OpenCollection.new(title: 'My Product', description: 'A product', amount: 200)
    collection.create

    assert collection.success?
    assert_requested :post, "#{LIVE}/v3/open_collections",
      body: { 'title' => 'My Product', 'description' => 'A product', 'amount' => '200' }
  end

  def test_create_requires_amount_when_the_amount_is_fixed
    error = assert_raises(ArgumentError) do
      Billplz::OpenCollection.new(title: 'My Product', description: 'A product').create
    end

    assert_match(/amount/, error.message)
  end

  # A variable-amount collection is priced by the payer, so amount is ignored.
  def test_create_without_amount_when_the_amount_is_not_fixed
    stub_api(:post, "#{LIVE}/v3/open_collections", body: OPEN_COLLECTION)

    Billplz::OpenCollection.new(title: 'Donation', description: 'Give', fixed_amount: false).create

    assert_requested :post, "#{LIVE}/v3/open_collections", body: hash_including('fixed_amount' => 'false')
  end

  # redirect_uri is v4 only.
  def test_v4_create_with_redirect_uri
    stub_api(:post, "#{LIVE}/v4/open_collections", body: OPEN_COLLECTION)

    payload = { title: 'My Product', description: 'A product', amount: 200,
                redirect_uri: 'https://example.com/done' }
    Billplz::OpenCollection.new(payload, version: 'v4').create

    assert_requested :post, "#{LIVE}/v4/open_collections",
      body: hash_including('redirect_uri' => 'https://example.com/done')
  end

  def test_get
    stub_api(:get, "#{LIVE}/v3/open_collections/inbmmepb", body: OPEN_COLLECTION)

    Billplz::OpenCollection.new(collection_id: 'inbmmepb').get

    assert_authorized :get, "#{LIVE}/v3/open_collections/inbmmepb"
  end

  def test_index
    stub_api(:get, "#{LIVE}/v3/open_collections?page=2", body: '{"open_collections":[],"page":"2"}')

    Billplz::OpenCollection.new(page: 2).index

    assert_requested :get, "#{LIVE}/v3/open_collections?page=2"
  end
end

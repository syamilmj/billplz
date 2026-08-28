# Billplz

[![Gem Version](https://badge.fury.io/rb/billplz.svg)](https://badge.fury.io/rb/billplz)

A dependency-free Ruby client for the [Billplz API](https://www.billplz.com/api), covering v3, v4 and v5.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'billplz'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install billplz
```

Requires Ruby 3.1 or newer.

## Configuration

```ruby
# config/initializers/billplz.rb
Billplz.configure do |config|
  config.api_key         = ENV['BILLPLZ_API_KEY']
  config.x_signature_key = ENV['BILLPLZ_X_SIGNATURE_KEY']
  config.mode            = ENV.fetch('BILLPLZ_MODE', 'live')  # or 'sandbox'
  config.http_timeout    = 30
end
```

`api_key` and `x_signature_key` are two different credentials. The API key authenticates your requests; the X Signature key verifies that callbacks and redirects genuinely came from Billplz.

Setting `mode` to `'sandbox'` points every request at `www.billplz-sandbox.com` instead of `www.billplz.com`. Sandbox has its own separate keys.

All the options above can be overridden at runtime:

```ruby
Billplz.configuration.api_key = 'your-api-key'
```

Or, as a hash:

```ruby
Billplz.configuration = { api_key: 'your-api-key', mode: 'sandbox' }
```

## Bills

```ruby
bill = Billplz::Bill.new(
  collection_id: 'iyvoxe8f',
  email:         'customer@example.com',   # email or mobile is required
  name:          'Customer Name',
  amount:        200,                      # in cents
  callback_url:  'https://example.com/billplz/callback',
  description:   'Invoice #123',
  redirect_url:  'https://example.com/billplz/redirect'
)
bill.create

bill.parsed_json['url']   # send the customer here to pay
```

Get a bill:

```ruby
bill = Billplz::Bill.new(bill_id: 'abc123')
found = bill.get                # parsed hash, or nil if the request failed

found['state']                  # due, paid or deleted
found['paid']                   # false for due, true for paid
```

Delete a bill (only while it is `due`):

```ruby
Billplz::Bill.new(bill_id: 'abc123').delete
```

List a bill's transactions:

```ruby
Billplz::Bill.new(bill_id: 'abc123', page: 1, status: 'completed').transactions
```

## Verifying callbacks and redirects

Billplz signs its callbacks and redirects so you can tell a real payment notification from anyone else POSTing to your endpoint. Verify every one of them before you mark an order as paid:

```ruby
class BillplzController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback

  def callback
    head :bad_request and return unless Billplz::Signature.verify(params.to_unsafe_h)

    Order.find_by!(bill_id: params[:id]).mark_paid! if params[:paid] == 'true'
    head :ok
  end

  def redirect
    @verified = Billplz::Signature.verify(params.to_unsafe_h)
  end
end
```

`Signature.verify` handles both shapes — the callback's flat params and the redirect's `billplz[...]` nesting — whether your framework hands them over already parsed or still as literal `"billplz[id]"` keys. It reads `Billplz.configuration.x_signature_key` by default; pass a key as the second argument to override it.

Note that the callback and the redirect are independent and arrive in no guaranteed order. Treat both as idempotent.

## Collections

```ruby
collection = Billplz::Collection.new(title: 'My awesome collection')
collection.create

Billplz::Collection.new(collection_id: 'bnck5esg').get
Billplz::Collection.new(page: 1, status: 'active').index

Billplz::Collection.new(collection_id: 'bnck5esg').activate
Billplz::Collection.new(collection_id: 'bnck5esg').deactivate
```

Collections default to v3. Pass `version: 'v4'` for two-recipient split rules:

```ruby
Billplz::Collection.new({
  title:        'Split collection',
  split_header: true,
  split_payments: [
    { email: 'partner@example.com', fixed_cut: 100, stack_order: 0 },
    { email: 'agent@example.com',   variable_cut: 3, stack_order: 1 }
  ]
}, version: 'v4').create
```

Payment methods:

```ruby
Billplz::Collection.new(collection_id: 'bnck5esg').payment_methods

# enables exactly these, disables everything else
Billplz::Collection.new(collection_id: 'bnck5esg', payment_methods: %w[fpx paypal]).update_payment_methods
```

Customer receipt delivery (v4):

```ruby
collection = Billplz::Collection.new(collection_id: 'bnck5esg')
collection.customer_receipt_delivery              # active, inactive or global
collection.activate_customer_receipt_delivery
collection.deactivate_customer_receipt_delivery
collection.global_customer_receipt_delivery       # revert to the account default
```

## Open collections

```ruby
Billplz::OpenCollection.new(
  title:       'My Product',
  description: 'A very good product',
  amount:      200
).create

Billplz::OpenCollection.new(collection_id: 'inbmmepb').get
Billplz::OpenCollection.new(page: 1).index
```

Pass `version: 'v4'` for `redirect_uri` and two-recipient split rules.

## Payment gateways

```ruby
Billplz::PaymentGateway.new.index   # v4, every gateway code with its active flag
Billplz::FpxBank.new.index          # v3, FPX bank codes only
Billplz::WebhookRank.new.get        # your callback delivery standing, 0.0 (best) to 10.0
```

Billplz asks that gateway and bank lists be pulled hourly rather than per request.

## Payment orders (v5)

Payment orders disburse funds out. Like bills, they live inside a collection. Every v5 request is signed with an `epoch` and an HMAC-SHA512 `checksum`, both of which this gem adds for you from `x_signature_key`.

```ruby
collection = Billplz::PaymentOrderCollection.new(
  title:        'August payroll',
  callback_url: 'https://example.com/billplz/payment_orders'
)
collection.create

order = Billplz::PaymentOrder.new(
  payment_order_collection_id: collection.parsed_json['id'],
  bank_code:           'MBBEMYKL',      # recipient bank SWIFT code
  bank_account_number: '1234567890',
  name:                'Recipient Name',
  description:         'August salary',  # no special characters
  total:               100_000
)
order.create

Billplz::PaymentOrder.new(payment_order_id: 'pmo1').get
Billplz::PaymentOrderLimit.new.get       # funds available to disburse
```

In sandbox, only `bank_code: 'DUMMYBANKVERIFIED'` succeeds. `PaymentOrderLimit` is rate limited well below the general limit — 3 requests per 10 minutes in production.

## Response

Every method returns the standard `Net::HTTP` response. The gem adds a few helpers:

```ruby
bill.success?        # true for any 2xx
bill.parsed_json     # the response body parsed as JSON
bill.error           # the API's error object, or nil on success
bill.rate_limited?   # true on 429
bill.rate_limit      # { limit:, remaining:, reset: } from the RateLimit-* headers
```

`error` is a hash of `type` and `message`. Billplz documents `message` as an array, but some endpoints return a string and a couple return a nested hash — do not assume its shape.

Rate limits apply to GET endpoints only, cumulatively per account or IP over a rolling five-minute window.

## Not supported

- **Collection logos and open collection photos.** Both are multipart uploads; v4 dropped custom collection logos entirely.
- **Bank verification services** (`/v3/bank_verification_services`). Removed from the Billplz documentation in April 2023.
- **DuitNow Pay consents and auto-debit** (`/v5/duitnow/pay/*`). Withdrawn from the public documentation in September 2025 "until further notice".

## Development

Run `rake test` to run the unit tests. They stub every HTTP request and never touch the network.

`rake test:remote` runs against the real Billplz **sandbox** and is excluded from the default task. It skips itself unless you give it a key:

```
$ BILLPLZ_API_KEY=your-sandbox-key rake test:remote
```

Never point it at a production key — it creates and deletes real records.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/syamilmj/billplz. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

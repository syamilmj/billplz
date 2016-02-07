# Billplz

[![Gem Version](https://badge.fury.io/rb/billplz.svg)](https://badge.fury.io/rb/billplz)
[![Circle CI](https://circleci.com/gh/tideee/billplz.svg?style=shield&circle-token=:circle-token)](https://circleci.com/gh/tideee/billplz)
[![Code Climate](https://codeclimate.com/github/tideee/billplz/badges/gpa.svg)](https://codeclimate.com/github/tideee/billplz)

An abstraction library to interface with the [Billplz API](https://www.billplz.com/api)

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

## Usage

**Configuration**

You may store your Billplz configuration during initialization:

```ruby
# config/initializers/billplz.rb
Billplz.configure do |config|
  config.api_key = ENV['BILLPLZ_API_KEY']
end
```

All the options above can be overridden during runtime:

```ruby
Billplz.configuration.api_key = 'your-api-key'
```

Or, as a hash:

```ruby
Billplz.configuration = { api_key: 'your-api-key' }
```

**Collection**

Create a new collection:

```ruby
collection = Billplz::Collection.new({ title: 'My awesome collection' })
collection.create
```

**Bill**

Create a new bill:

```ruby
bill = Billplz::Bill.new({ collection_id: VALID_COLLECTION_ID, ... })
bill.create
```

Get a bill:

```ruby
bill = Billplz::Bill.new({ bill_id: 'abc123'})
bill.get
```

Delete a bill:

```ruby
bill = Billplz::Bill.new({ bill_id: 'abc123'})
bill.delete
```

**Response**

Standard Net::HTTP response will be returned by all of the above methods. However, the gem packed a few helper methods to make your life easier:

1. `#success?`

  You can check for a successfull request using `success?`, example:

  ```
  bill.success?
  ```

2. `#parsed_json`

  A convenient helper to parse the JSON response from the API, example:

  ```ruby
  bill_id = bill.parsed_json['id']
  ```

## Development

Run `rake test` to run the unit tests.

Running `rake test:remote` will run tests that perform actual communication with the API server. Proceed with caution.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tideee/billplz. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

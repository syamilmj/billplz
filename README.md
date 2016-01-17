# Billplz

An abstraction library to interface with the [Billplz API](https://www.billplz.com/api)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'billplz'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install billplz

## Usage

** Configuration **

1. You may store your Billplz configuration during runtime:

```ruby
# config/initializers/billplz.rb
Billplz.configure do |config|
  config.api_key      = ENV['BILLPLZ_API_KEY']
end
```

2. All the options above can be overridden manually:

```ruby
Billplz.configuration.api_key      = 'your-api-key'
```

3. Or, as a hash:

```ruby
Billplz.configuration = { api_key: 'your-api-key' }
```

** Collection **

Create a new collection:

```ruby
collection = Billplz::Collection.new({ title: 'My awesome collection' })
collection.create
```

** Bill **

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

** Response **

Standard Net::HTTP response will be returned by all of the above methods. However, the gem packed a few helper methods to make your life easier:

1. `#success?`

You can check for a successfull request using `success?`, example:

```
bill.success?
```

2. `#parsed_json`

This is a convenient helper to parse the JSON response from the API, example:

```ruby
bill_id = bill.parsed_json['id']
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Running `rake test:remote` will run tests that performs actual communication with the API server. Proceed with caution.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/syamilmj/billplz. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

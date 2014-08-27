# Agouti

Gem for testing above the fold render on the first tcp round trip.

This gem is a Rack middleware that truncates the gzipped response to 14kb.

Usefull for testing [critical rendering path optimization](https://developers.google.com/web/fundamentals/performance/critical-rendering-path/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'agouti'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install agouti

## Usage

To request the content of thew first round trip 

## Contributing

1. Fork it ( https://github.com/CWISoftware/agouti/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

# BBLib

BBLib (Brandon-Black-Lib) is a collection of various reusable methods and classes to extend the Ruby language. Currently the library is in an early state and is being written generally for education purposes. As such, large changes will likely occur and some functions may be incomplete or inaccurate until 1.0.

One of my primary goals with the core BBLib code is to keep it as lightweight as possible. This means you will not find dependencies outside of the Ruby core libraries in this code. Further modules that do have larger dependencies will be released in separate gems.

For a full breakdown of what is currently in this library, scroll down.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bblib'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bblib

## Usage

BBLib is currently broken up into the following categories:
* File
* Hash
* Math
* Net
* String
* Time

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bblack16/bblib. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

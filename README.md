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

### File
**File Scanners**
Various simple file scan methods are available. All of these are toggleable-recursive and can be passed filters using an wildcarding supported by the Ruby Dir.glob() method.
```ruby
# Scan for any files or folders in a path
BBLib.scan_dir 'C:/path/to/files'

#=> 'C:/path/to/files/readme.md'
#=> 'C:/path/to/files/license.txt'
#=> 'C:/path/to/files/folder/'
```

If you need only files or dirs but not both, the following two convenience methods are also available:
```ruby
# Scan for files ONLY
BBLib.scan_files 'C:/path/to/files'

#=> 'C:/path/to/files/readme.md'
#=> 'C:/path/to/files/license.txt'

# Scan for folders  ONLY
BBLib.scan_dirs 'C:/path/to/files'

#=> 'C:/path/to/files/folder/'
```

All of the scan methods also allow for the following named arguments:
* **recursive**: Default is false. Set to true to recursively scan directories
* **filter**: Default is nil. Can take either a String or Array of Strings. These strings will be used as filters so that only matching files or dirs are returned (Ex: '*.jpg', which would return all jpg files.)

```ruby
# Scan for any 'txt' or 'jpg' files recursively in a dir
BBLib.scan_dir 'C:/path/to/files', recursive: true, filter: ['*.jpg', '*.txt']

#=> 'C:/path/to/files/license.txt'
#=> 'C:/path/to/files/folder/profile.jpg'
#=> 'C:/path/to/files/folder/another_folder/text.txt'
```

In addition, both _scan_files_ and _scan_dirs_ also support a **mode** named argument. By default, this argument is set to :path. In _scan_files_ if :file is passed to :mode, a ruby File object will be returned rather than a String representation of the path. Similarily, if :dir is passed to _scan_dirs_ a ruby Dir object is returned.

### Hash


### Math


### Net
Currently empty...

### String


### Time


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bblack16/bblib. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

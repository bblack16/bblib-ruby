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
#### File Scanners

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

#### File Size Parsing

A file size parser is available that analyzes known patterns in a string to construct a numeric file size. This is very useful for parsing the output from outside applications or from web scrapers.

```ruby
# Turn a string into a file size (in bytes)
BBLib.parse_file_size "1MB 100KB"

#=> 1150976.0
```

By default the output is in bytes, however, this can be modified using the named argument **output**.

```ruby
# Turn a string into a file size (in bytes)
BBLib.parse_file_size "1MB 100KB", output: :megabyte

#=> 1.09765625

# The method can also be called directly on a string

"1.5 Mb".parse_file_size output: :kilobyte

#=> 1536.0
```

All of the following are options for output:
* :byte
* :kilobyte
* :megabyte
* :gigabyte
* :terabtye
* :petabtye
* :exabtye
* :zettabtye
* :yottabtye

Additionally, ANY matching pattern in the string is added to the total, so a string such as "1MB 1megabyte" would yield the equivalent of "2MB". File sizes can also be intermingled with any other text, so "The file is 2 megabytes in size." would successfully parse the file size as 2 megabytes.

#### Other Methods

**string_to_file**

This method is a convenient way to write a string to disk as file. It simply takes a path and a string. By default if the path does not exist it will attempt to create it. This can be controlled using the mkpath argument.

```ruby
# Write a string to disk
string = "This is my wonderful string."
BBLib.string_to_file '/home/user/my_file', string

# OR to avoid the creation of the path if it doesn't exist:

BBLib.string_to_file '/home/user/my_file', string, false

# OR call the method directly on the string

string.to_file '/home/user/another_file', true
```

### Hash

#### Deep Merge

A simple implementation of a deep merge algorithm that merges two hashes including nested hashes within them. It can also merge arrays (default) within the hashes and merge values into arrays (not default) rather than overwriting the values with the right side hash.

```ruby
h1 = ({value: 1231, array: [1, 2], hash: {a: 1, b_hash: {c: 2, d:3}}})
h2 = ({value: 5, array: [6, 7], hash: {a: 1, z: nil, b_hash: {c: 9, d:10, y:10}}})

# Default behavior merges arrays and overwrites non-array/hash values
h1.deep_merge h2

#=> {:value=>5, :array=>[1, 2, 6, 7], :hash=>{:a=>1, :b_hash=>{:c=>9, :d=>10, :y=>10}, :z=>nil}}

# Don't overwrite colliding values, instead, place them into an array together
h1.deep_merge h2, overwrite_vals: false

#=> {:value=>[1231, 5], :array=>[1, 2, 6, 7], :hash=>{:a=>[1, 1], :b_hash=>{:c=>[2, 9], :d=>[3, 10], :y=>10}, :z=>nil}}

# Don't merge arrays, instead, overwrite them.
h1.deep_merge h2, merge_arrays: false

#=> {:value=>5, :array=>[6, 7], :hash=>{:a=>1, :b_hash=>{:c=>9, :d=>10, :y=>10}, :z=>nil}}
```

A **!** version of _deep_merge_ is also available to modify the hash in place rather than returning a new hash.

#### Keys To Sym

Convert all keys within a hash (including nested keys) to symbols. This is useful after parsing json if you prefer to work with symbols rather than strings. __An inplace (**!**) version of the method is also available.__

```ruby
h = {"author" => "Tom Clancy", "books" => ["Rainbow Six", "The Hunt for Red October"]}
h.keys_to_sym

#=> {:author=>"Tom Clancy", :books=>["Rainbow Six", "The Hunt for Red October"]}
```

#### Reverse

Similar to reverse for Array. Calling this will reverse the current order of the Hash's keys. An inplace version is also available.

```ruby
h = {a:1, b:2, c:3, d:4}
h.reverse

#=> {:d=>4, :c=>3, :b=>2, :a=>1}
```

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

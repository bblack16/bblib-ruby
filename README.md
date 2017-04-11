# BBLib

BBLib is a collection of various methods and classes that aim to extend the Ruby language. One of the primary goals with the BBLib is to keep it as lightweight as possible. This means you will not find dependencies outside of the Ruby core libraries.

Good news! BBLib is now compatible with Opal! Well, like 90% compatible (some portions are excluded when running in Opal), but it can be 100% compiled into Javascript. Only very small tweaks were made to support this, so base functionality for the BBLib outside of Opal remains the same. But now it can coexist as both a Ruby gem, and an Opal library.

BBLib contains A LOT of functionality, but is a very small, lightweight library. As such, it can be hard to document everything that is included (and even harder to make a TL:DR version). The usage section below contains most of the highlights and important features. The source code contains the rest.

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

### Hash Path

HashPath is a set of functions, classes and extensions to the native ruby hash and array classes. It allows to items to be retrieved from a hash using a dot delimited syntax, similar to XPath for XML. It also provides methods for moving, copying and deleting paths within hashes as well as modifying the contents of nested paths with hashes.

Below are several examples.

```ruby
hash = { a: 1, b: 2, c: [3, 4, { d: 5 }, 6], e: { f: { g: 'test', a: 99 } } }

hash.hpath('a') # Normal hash like navigation
# => [1]  <- Always returns an array
hash.hpath('..a') # Recursive navigation
# => [1, 99]
hash.hpath('/[abc]/')
# => [1, 2, [3, 4, {:d=>5}, 6]]

hash.hpaths # => View the absolute paths of a hash or array
# => ["a", "b", "c.[0]", "c.[1]", "c.[2].d", "c.[3]", "e.f.g", "e.f.a"]

hash.hpath_move('c.[0]' => 'z') # Array access and moving
# => {:a=>1, :b=>2, :c=>[4, {:d=>5}, 6], :e=>{:f=>{:g=>"name", :a=>99}}, :z=>3}
hash.hpath_copy('e..g' => 'z', 'a' => 'ary') # Array access and moving
# => {:a=>1, :b=>2, :c=>[3, 4, {:d=>5}, 6], :e=>{:f=>{:g=>"name", :a=>99}}, :z=>"name", :ary=>1}
hash.hpath_delete('e.f.g') # Delete elements using path notation
# => {:a=>1, :b=>2, :c=>[3, 4, {:d=>5}, 6], :e=>{:f=>{:a=>99}}}
hash.hpath_set('e.f.g' => 'name') # Set nested value
# => {:a=>1, :b=>2, :c=>[3, 4, {:d=>5}, 6], :e=>{:f=>{:g=>"name", :a=>99}}}
```

#### Path options

- __Standard__ (e.g. 'a') - Matches any key that is either :a or 'a'
- __Recursive__ (e.g. '..a') - Matches any key :a or'a' any where in the nested hashes/arrays.
- __Regexp__ (e.g. '/example/') - Finds all keys that match the regular expression /example/
- __Array Element__ (e.g. '[0]') - Finds the element at index 0.
- __Range__ (e.g. '[0..2]') - Returns the first 3 elements of any matching array.
- __Parent__ (e.g. '{parent}') - Returns the parent of the current position.
- __Root__ (e.g. '{root}') - Navigates to the root of the current Hash/Array.
- __Siblings__ (e.g. '{siblings}') - Returns the siblings of the current Hash/Array.
- __Expression__ (e.g. 'a(value > 10)') - Returns elements if the expression in the parenthesis evaluates to true. _value_ holds a reference to the current position of navigation. The example would return any items under the key 'a' that have a value greater than 10.

### TreeHash

TreeHash is a container that wraps a Hash or Array. It provides all of the navigation and functionality used in HashPath. It provides the ability to navigate hashes both forwards and backwards, similar to the DOM of XML or a webpage.

```ruby
hash = { a: 1, b: 2, c: [3, 4, { d: 5 }, 6], e: { f: { g: 'test', a: 99 } } }
tree = hash.to_tree_hash

tree[:e][:f][:g].parent # Standard hash navigation and usage of parent to backtrack
# => {:g=>"test", :a=>99}
tree.find('e..a') # HashPath uses this method for navigatio. Here it returns an Array of TreeHash objects.
# => [99]
tree.find('e..a').first.siblings # Get siblings. next_sibling and previous_sibling are also available
# => [test]
```

### String

```ruby
str = 'this is an example'

# Cases
str.snake_case
# => 'this_is_an_example'
str.title_case
# => 'This Is an Example'
# Also available: start_case, camel_case, train_case, spinal_case, delimited_case(custom)

# General
'12.9 MB version 1.1.9 20 total'.extract_numbers
# => [12.9, 20]
'12.9 MB version 1.1.9 20 total'.extract_integers
# => [20]
'12.9 MB version 1.1.9 20 total'.extract_floats
# => [12.9]

'Simpsons, The'.move_articles(:front) # or :back or :none
# => 'The Simpsons'

# Simple shortening with various truncation options
str = 'This string is longer than I want it to be for display purposes'
BBLib.chars_up_to(str, 10)
# => 'This strin...'
BBLib.chars_up_to(str, 10, style: :back)
# => '...y purposes'
BBLib.chars_up_to(str, 10, style: :outter)
# => "This ...poses"
BBLib.chars_up_to(str, 10, style: :middle)
# => "... I want it..."

# Basic pluralization without the need for large models
BBLib.pluralize(1, 'Test')
# => 'Test'
BBLib.pluralize(2, 'Test')
# => 'Tests'
BBLib.pluralize(99, 'Quer', 'ies', 'y')
# => 'Queries'

# Multi Split
'this is-a+test'.msplit(' ', '-', /\+/)
# => ['this', 'is', 'a', 'test']

# Split unless not in quotes
'an,"example,of,some",kind'.quote_split(',')
# => ["an", "\"example,of,some\"", "kind"]

# Regular Expressions
'/test/i'.to_regex # Convert the /.../ version of a regex string to a Regex.
# => /test/i

# String encapsulation methods
str = 'test'
str.encapsulate('[') # Encapsulate a string. Recognizes (, [, { and < as (), [], {} and <>.
# => '[test]'
str.encapsulate('S')
# => 'StestS'
str.encap_by?('t') # Check if a string begins and ends with a char or string. Recognizes (, [, { and < as (), [], {} and <>.
# => true
'(example)'.uncapsulate('(') # Remove encapsulataion. Recognizes (, [, { and < as (), [], {} and <>.
# => 'example'

# Roman numerals
'Quake III'.from_roman # Converts roman numerals in a string to integers
# => 'Quake 3'
'Fallout 4'.to_roman # Converts integers in a string to roman numerals
# => 'Fallout IV'
5.to_roman # Also available directly on Integers.
# => 'V'

# String fuzzy matching
'Ruby'.levenshtein_similarity('Rails') # Basic implementation of the Levenshtein distance algorithm. Returns the percentage match. levenshtein_distance is also availabe and returns the computed distance.
# => 20.0
'Ruby'.composition_similarity('Rails') # Returns the % of characters that are the same between two strings. The number of occurences is also checked for each character.
# => 20.0
'Sinatra is Elegant'.phrase_similarity('Ruby is Fun') # Returns the amount of words that match between two strings as a percentage.
# => 33.333333333

```

### FuzzyMatcher

BBLib::FuzzyMatcher is a class that utilizes the string comparison algorithms shown above as well as the string normalization methods show (convert roman numerals, move articles, etc...) to compare strings. It is most useful for comparing titles or for basic searching.

There are 4 algorithms that can be used for matching:
- levenshtein
- composition
- numeric
- phrase

```ruby
fm = BBLib::FuzzyMatcher.new(
                              case_sensitive: false,
                              convert_roman: true,
                              move_articles: true,
                              remove_symbols: true
                            )

fm.similarity('Learn Ruby', 'Learn Java') # Returns the percentage of similarity between two strings
# => 60.0
fm.threshold = 60 # Sets a threshold to match for certain methods (like match?)
fm.match?('Elixir', 'C++') # True if two strings have a match percent equal to or greater than the threshold.
# => false
fm.match?('Elixir', 'Elixr')
# => true
fm.best_match('Ruby', 'Elixir', 'JRUBY', 'Java', 'C++') # Find the best match amongst an Array for the first argument.
# => 'JRUBY'
fm.similarities('Ruby', 'Elixir', 'JRUBY', 'Java', 'C++') # Return a hash with how similar an array of words are (by %)
# => {"Elixir"=>5.5555555555555545, "JRUBY"=>80.0, "Java"=>0.0, "C++"=>0.0}
```

By default, levenshtein and composition are used, and levenshtein is weighted at 10, while composition is 5. The other algorithms can be turned on, or have their weights adjusted using the set_weight method. A weight of 0 is effectively turning off that algorithm. Any other value is arbitrary, but determines how much the match % of that algorithm affects the global match %.

```ruby
fm.set_weight(:numeric, 5) # Set numeric to a weight of 5
fm.set_weight(:composition, 0) # Turn composition off
```

### File

```ruby
# Scan a directory for files using filters. Can be toggled to be recursive.
# Filters can be strings or regular expressions. If the string contains an *
# it will be treated as a .* in a regexp.
# If a block is not passed, this will return an array of strings (paths)
BBLib.scan_dir('/var/logs', '*.log', /\.txt/, recursive: true) do |file|
  # Do something with file...
end

BBLib.scan_files # Same as above, but only matches files (not directories)
BBLib.scan_dirs # Matches only directories, files are ignored

# Simple string to file method
# This is a convenience method that uses File.write but can also generate the path to the file if it does not already exist.
# It can be called directly on a string or by BBLib.string_to_file(str, path, opts = {})
'I want this on disk'.to_file('/opt/my_path/test.txt', mode: 'a') # Write a string to disk

# Parsing file sizes from strings
'1MB 156 kB'.parse_file_size # Parse file size from a string (cumulative). By default this will return the size in bytes.
# => 1208320.0
# Adjust the output to be in megabytes
# Other options are :byte, :kilobyte, :megabyte, :gigabyte, :terabyte, :petabyte, :exabyte, :zettabyte, :yottabyte
'1MB 156 kB'.parse_file_size(output: :megabyte)
# => 1.15234375
'The file size is 19.5 megabytes. Proceed?'.parse_file_size # Can parse from the middle of a string
# => 20447232.0
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bblack16/bblib. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

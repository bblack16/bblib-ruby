# BBLib

BBLib is a collection of reusable methods and classes that are helpful to have in most Ruby applications or scripts. There is a lot of content here and you should be warned that BBLib does MonkeyPatch several Ruby classes (Hash, Array, String, Integer, Float). The Usage section below covers some of the highlights but for complete coverage of everything included, take a look at the YARD documentation.

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

### Effortless

BBLib provides a collection of mixins meant to DRY up Ruby as much as possible. The collection of these mixins are brought together in Effortless. There are many things that classes that implement effortless can benefit from. Here is a quick breakdown of some of what it adds:

- New attr methods to store specific object types (like attr_string or attr_bool)
- Automatic creation of initialize method based on attr methods (never write an initialize again!)
- Automatic serialization (to Hash) based on attr methods (or other methods). Plus you can then instantiate Effortless classes from these serializations.
- Hooks for methods. Create simple before and after hooks to ensure certain methods are called before or after any others.
- Ability to find all subclasses of a class or all instantiations of a class.

How about an example?
```ruby
# All we have to do is include the BBLib::Effortless module in a class
class Cat
  include BBLib::Effortless

  GENDER = [:unknown, :male, :female].freeze

  # Now create getters/setters for our cat attributes
  attr_str :name, arg_at: 0, required: true
  attr_date :birthday
  attr_element_of GENDER, :gender, default: :unknown
  attr_int :age

  # Create after hook to calculate the cat's age every time the birthday setter is called
  after :birthday=, :calculate_age

  def calculate_age
    self.age = Time.now.year - birthday.year
  end

end

# Now we can create cat objects using our attr methods
my_cat = Cat.new(name: 'Jackson', birthday: '2014-05-20', gender: :male)
puts my_cat
# => #<Cat:0x0000000005b4b310>

# Since name has the arg_at option set to element 0, we can also create a Cat like this
# (where the cat's name is the first unnamed argument)
your_cat = Cat.new('Nehra', birthday: '2017-02-14', gender: :female)
p your_cat
# => #<Cat:0x0000000005bc5ed0 @name="Nehra", @birthday=#<Date: 2017-02-14 ((2457799j,0s,0n),+0s,2299161j)>, @age=1, @gender=:female>

# We can then serialize the class into a hash
puts my_cat.serialize
# => {:name=>"Jackson", :birthday=>#<Date: 2014-05-20 ((2456798j,0s,0n),+0s,2299161j)>, :gender=>:male, :age=>4}
```

#### attr_ Methods

As shown in the example above, once BBLib::Effortless is included into a class a new set of attr methods become available within it to automatically build getters/setters. Here is a break down of the available attr methods, what they do and what options are available to them.

##### General

First, here are the global options available to all attr methods. Options are passed to the attr methods as named parameters. The object/value types in the square brackets indicate the type of value each argument expects.

- __required__: [true/false] Used by the SimpleInit module. If set to true, an exception will be raised when this class is instantiated unless this variable is passed to the constructor.
- __allow_nil__: [true/false] Most attr methods have type casting that occurs or will throw errors when being set to nil (or any unexpected object type). If you wish to allow nil to be set to your instance variable, set allow_nil to true.
- __serialize__: [true/false] When set to false this method will not be returned in the .serialize method.
- __default__: [Object] Sets the default value for this attr method if nothing is passed in.
- __default_proc__: [Proc, Symbol] A proc or symbol can be passed in. This works similarly to default but instead calls the Proc or method (Symbol) and sets the default to the result. This is useful when the default is based on an external source that is dynamic.
- __aliases__: [Array of Symbols] Creates an alias to the method for each alias passed in.
- __singleton__: [true/false] When set to true the method is placed on the singleton class as a class method rather than an instance method.
- __private__: [true/false] When set to true the getter and setter are set to private. To specifically make the getter or setter private you can instead use :private_reader or :private_writer
- __protected__: [true/false] Same as private, but the methods will be protected.
- __pre_proc__: [Proc, Symbol] When provided, the Proc or method (Symbol) will be called and passed the value being sent to the setter for pre processing. For example, this can be used to downcase a string being set in an attr_str setter.

##### attr_string

__attr_string__ or __attr_str__ can be used to create a getter/setter pair that will store a string. Any argument being passed to the setter will have to_s called on it (unless it is nil and allow_nil is set to true).

```ruby
# Usage: attr_str <method_name>, [options]
attr_str :first_name, default: 'Unknown'
```
- *There are no special options for attr_string*

##### attr_symbol

__attr_symbol__ or __attr_sym__ creates a getter and setter that will store a symbol. Any value being passed in will have to_sym called on it.

```ruby
# Usage: attr_sym <method_name>, [options]
attr_sym :http_method, default: :get, serialize: false
```
- *There are no special options for attr_symbol*

##### attr_of

__attr_of__ creates a getter and setter that will allow only the specified class types to get set to it. If the class type is a BBLib::Effortless class, hashes (serializations) may be passed in to the setter and they will automatically be instantiatedas the object type (if able).

```ruby
# Usage: attr_of <class>, <method_name>, [options]
#        attr_of [<class1>, <class2>], <method_name>, [options]
attr_of Regexp, :expression, required: true
attr_of [String, Symbol], :attribute, default: :general
```

The following special options are available to attr_of:
- __pack__: [true/false] When set to false the behavior that allows hases to be used as constructor arguments for a Effortless class will be disabled and allowed classes will have to already be instantiated before being passed to the setter.
- __suppress__: [true/false] By default if an object is passed to the setter that is not an object matching any of the allowed classes an exception is raised. Setting suppress to true will disable this behavior and instead the invalid object will simply be ignored (not set).

#### MORE TO COME...

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

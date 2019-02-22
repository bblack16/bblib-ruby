# BBLib

BBLib is a collection of reusable methods and classes that are helpful to have in most Ruby applications or scripts. There is a lot of content here and you should be warned that BBLib does MonkeyPatch several Ruby classes (Hash, Array, String, Integer, Float). The Usage section below covers some of the highlights but for complete coverage of everything included, take a look at the YARD documentation.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Effortless](#effortless)
    - [Attrs](#attrs)
      - [Disclaimer](#disclaimer)
      - [General](#general)
      - [attr_string](#attr_string)
      - [attr_symbol](#attr_symbol)
      - [attr_integer && attr_float](#attr_integer-attr_float)
      - [attr_boolean](#attr_boolean)
      - [attr_integer_between && attr_float_between](#attr_integer_between-attr_float_between)
      - [attr_integer_loop && attr_float_loop](#attr_integer_loop-attr_float_loop)
      - [attr_array](#attr_array)
      - [attr_hash](#attr_hash)
      - [attr_of](#attr_of)
      - [attr_array_of](#attr_array_of)
      - [attr_element_of](#attr_element_of)
      - [attr_elements_of](#attr_elements_of)
      - [attr_file](#attr_file)
      - [attr_dir](#attr_dir)
      - [attr_time && attr_date](#attr_time-attr_date)
    - [Simple Init](#simple-init)
    - [Family Tree](#family-tree)
    - [Bridge](#bridge)
    - [Hooks](#hooks)
    - [Serializer](#serializer)
  - [Hash Path](#hash-path)
    - [Path options](#path-options)
  - [TreeHash](#treehash)
  - [String Methods](#string-methods)
  - [FuzzyMatcher](#fuzzymatcher)
  - [Numeric Methods](#numeric-methods)
  - [OS / System Methods](#os-system-methods)
  - [Time Methods](#time-methods)
  - [Hash Methods](#hash-methods)
  - [Array Methods](#array-methods)
  - [File Methods](#file-methods)
  - [HTML Methods](#html-methods)
  - [Logging](#logging)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

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

#### Attrs

As shown in the example above, once BBLib::Effortless is included into a class a new set of attr methods become available within it to automatically build getters/setters. Here is a break down of the available attr methods, what they do and what options are available to them.

NOTE: All attr methods can take any number of method_names in one call. For example:
```ruby
# Create a string getter and setter for first_name, last_name and address
attr_str :first_name, :last_name, :address, required: true
```

The important thing to remember is that any arguments (such as required: in the example above) will apply to ALL of the methods on that line. So if, for example, address was not required but first_name and last_name were, the attr calls should look like this:

```ruby
attr_str :first_name, :last_name, required: true
attr_str :address
```

NOTE: The attr methods can be added without including all of Effortless by including only the BBLib::Attrs module.

##### Disclaimer

When using Effortless you should no longer declare or call instance variables in your class. Effortless takes care of creating these and setting default values to them when the corresponding method name is called. Calling them or interacting with them directly also bypasses the logic Effortless applies, so don't do it!

```ruby
class Dog
  include BBLib::Effortless
  attr_str :name
  attr_time :birthdate, default_proc: proc { Time.now }

  # FAIL, stop typing @!
  # The default_proc method would normally take care of setting a default so
  # that it is ensured @birthdate is a Date. In the case below, it's possible
  # @birthdate is undefined and an error will be thrown.
  def age
    @birthdate.year - Time.now
  end

  # Good
  # Calling the birthdate method will take care of setting the default value
  # if one has not already been set. This method will always work.
  def age
    birthdate.year - Time.now
  end

end
```

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

##### attr_integer && attr_float

__attr_integer__ or __attr_int__ creates a getter and setter that will store an Integer. __attr_float__ is similar but stores floats. to_i and to_f will be called respectively on any value passed in to the setter.

```ruby
# Usage: attr_int <method_name>, [options]
#        attr_float <method_name>, [options]
attr_int :size, default: 0

# Below we create a percent attribute and use a pre_proc to ensure
# percentage values greater than 1 are divided by 100.
attr_float :percent, pre_proc: proc { |x| x > 1.0 ? x / 100.0 : x }
```

- *There are no special options for attr_symbol*

##### attr_boolean

__attr_boolean__ or __attr_bool__ creates a getter and setter that will store true of false. Values passed in to the setter are considered to be true unless they are of NilClass or FalseClass. By default, __attr_boolean__ will also create an alias for the getter with a ? at the end (see example below).

```ruby
# Usage: attr_bool <method_name> [options]
attr_bool :active, default: false

# This creates the methods 'active' and 'active?' to return the value of the attribute.
```

The following special options are available to attr_bool:
- __no_?__: [true/false] When set to false the question mark version of the getter will not be created. (default is true)

##### attr_integer_between && attr_float_between
__attr_integer_between__ or __attr_int_between__ creates an integer getter and setter but ensures the value stored is between a min and max value. If the value exceeds the max it is set to max and if it is lower than min it is set to min. __attr_float_between__ is the same but stores floats between a min and max. To specify no max or no min, set min or max to nil (which means no bounds).

```ruby
# Usage: attr_int_between <min>, <max>, <method_name> [options]
#        attr_float_between <min>, <max>, <method_name> [options]
attr_int_between 0, 100, :score
attr_float_between 0, 1.0, :percent, default: 0
```

- *There are no special options for __attr_integer_between__*

##### attr_integer_loop && attr_float_loop

__attr_integer_loop__ is very similar to attr_integer_between with one key difference. If the max boundary is exceeded the value is instead set to the minimum. If the value is lower than min, the value is then set to max. Setting either min or max to nil would void this behavior and should not be done.

```ruby
# Usage: attr_integer_loop <min>, <max>, <method_name>, [options]
attr_integer_loop 0, 10, :counter, default: 0
```

- *There are no special options for __attr_integer_between__*

##### attr_array
__attr_array__ or __attr_ary__ creates a getter and setter for an Array. The Array will allow any type of objects to be store in it. If you wish to create an Array to store specific types of Objects see the __attr_array_of__ method. Several options are available including the ability to have the __attr_array__ method automatically create adder and remover methods (to add/remove items from the array without having to use the setter).

NOTE: It is unnecessary to specify the default as [], as that is done automatically.

```ruby
# Usage: attr_ary <method_name>, [options]
attr_ary :items, uniq: true
attr_ary :cats, add_rem: true, adder_name: :add_cat, remover_name: :remove_cat
```

The following special options are available for attr_array:
- __uniq__: [true/false] Ensures all items inside the array are unique. (default is false)
- __add_rem__: [true/false] Automatically creates an adder and remover method. They will be named add_<method_name> and remove_<method_name> by default. Naming can be defined in the adder_name and remover_name options. (default is false)
- __adder_name__: [String, Symbol] Sets a custom name for the adder method. add_rem must be set to true for this to matter.
- __remover_name__: [String, Symbol] Sets a custom name for the remover method. add_rem must be set to true for this to matter.


##### attr_hash

__attr_hash__ creates a getter and setter for a hash object. By default any keys and values are allowed but the types can be controlled using the *keys* and  *values* options. It is unnecessary to set the default to {} as that is done automatically.

NOTE: The keys and values options only enforces the types when the hash is set via the setter. If it is interacted with directly any object types will be allowed (as is standard for Ruby Hashes).

```ruby
# Usage: attr_hash <method_name>, [options]
attr_hash :options

# Create a hash that only allows Symbols for keys and strings or integers for values
attr_hash :attributes, keys: [Symbol], values: [String, Integer]
```

The following options are available to attr_hash:
- __keys__: [Array of Classes] An array of classes that are allowed to be used as keys. If an invalid type is passed in an exception is raised.
- __values__: [Array of Classes] An array of classes that are allowed to be used as values. If an invalid type is passed in an exception is raised.
- __symbol_keys__: [true/false] When set to true, all keys will be converted to symbols (recursively). This is useful if you want to convert string keys to symbols (such as when the hash is being read in as JSON). (default is false)

##### attr_of

__attr_of__ creates a getter and setter that will allow only the specified class types to get set to it. If the class type is a BBLib::Effortless class, hashes (serializations) may be passed in to the setter and they will automatically be instantiatedas the object type (if able).

```ruby
# Usage: attr_of <class>, <method_name>, [options]
#        attr_of [<class1>, <class2>], <method_name>, [options]
attr_of Regexp, :expression, required: true
attr_of [String, Symbol], :attribute, default: :general
```

The following special options are available to attr_of:
- __pack__: [true/false] When set to false the behavior that allows hashes to be used as constructor arguments for a Effortless class will be disabled and allowed classes will have to already be instantiated before being passed to the setter. (default is true)
- __suppress__: [true/false] By default if an object is passed to the setter that is not an object matching any of the allowed classes an exception is raised. Setting suppress to true will disable this behavior and instead the invalid object will simply be ignored (not set). (default is false)

##### attr_array_of

__attr_array_of__ or __attr_ary_of__ create a getter and setter for an Array that will only allow certain types of Objects to be stored in it. It works very similarly to __attr_array__ otherwise. If one of the allowed classes is a BBLib::Effortless class, this method can accept hashes and will attempt to instantiate objects uses the hashes as constructor arguments (similar to __attr_of__).

```ruby
# Usage: attr_ary_of <class>, <method_name>, [options]
#        attr_ary_of [<class1>, <class2>, <...>], <method_name>, [options]
attr_ary_of String, :names, uniq: true
attr_ary_of [Integer, Float], :scores, add_rem: true
```

The following special options are available to attr_array_of:
- __pack__: [true/false] When set to false the behavior that allows hashes to be used as constructor arguments for a Effortless class will be disabled and allowed classes will have to already be instantiated before being passed to the setter. (default is true)
- __suppress__: [true/false] By default if an object is passed to the setter that is not an object matching any of the allowed classes an exception is raised. Setting suppress to true will disable this behavior and instead the invalid object will simply be ignored. (default is false)
- __uniq__: [true/false] Ensures all items inside the array are unique. (default is false)
- __add_rem__: [true/false] Automatically creates an adder and remover method. They will be named add_<method_name> and remove_<method_name> by default. Naming can be defined in the adder_name and remover_name options. (default is false)
- __adder_name__: [String, Symbol] Sets a custom name for the adder method. add_rem must be set to true for this to matter.
- __remover_name__: [String, Symbol] Sets a custom name for the remover method. add_rem must be set to true for this to matter.

##### attr_element_of

__attr_element_of__ creates a getter and setter that allow only specific objects from an array to be passed to the setter. This is great for creating enumerators.

```ruby
# Usage: attr_element_of <element_array>, <method_name>, [options]
#        attr_element_of <element_proc+_or_symbol>, <method_name>, [options]
METHODS = [:get, :post, :put, :delete, :head].freeze

attr_element_of METHODS, :http_method, default: METHODS.first

# A Proc can be passed instead of an array but it's result should be an Array.
# This allows for the Element list to be more dynamic (such as being loaded from a file like below).
# If a Symbol is passed, it is sent to the class as a method to get a list.
attr_element_of proc { File.read('states.txt').split("\n") }, :state
```

- *There are no special options for __attr_element_of__*

##### attr_elements_of

__attr_elements_of__ is similar to attr_element_of except is stores an Array that only allows elements from the element list.

```ruby
# Usage: attr_elements_of <element_array>, <method_name>, [options]
#        attr_elements_of <element_proc_or_symbol>, <method_name>, [options]
FOODS = %w{apple orange banana pizza hamburger burrito donut}

attr_elements_of FOODS, :favorite_foods
```

- *There are no special options for __attr_elements_of__*

##### attr_file

__attr_file__ creates a getter and setter for a string, meant to be a valid path to a file. When the setter is called, an exception will be raised unless the string is a valid path to a file on disk.

```ruby
# Usage: attr_file <method_name>, [options]
attr_file :config_file
```

The following arguments are available for attr_file:
- __mkfile__: [true/false] When set to true, if a file does not exist at the specified path it will be created (via FileUtils.touch). (default is false)

##### attr_dir

attr_dir creates a getter and setter for a string, meant to be a valid path to a directory. When the setter is called, an exception will be raised unless the string is a valid path to a directory on disk.

```ruby
# Usage: attr_file <method_name>, [options]
attr_dir :configs, default: Dir.pwd
```

The following arguments are available for attr_dir:
- __mkpath__: [true/false] When set to true, if a path passed to the setter does not exist it will atempt to create it. (default is false)

##### attr_time && attr_date

__attr_time__ creates a getter and setter that stores a Time object. It provides basic parsing so it can accept strings and numbers to generate Time objects. By default this will try Time.parse for strings and Time.at for Numerics. Custom formats can also be passed in if the format is not recognized correctly by Time.parse. __attr_date__ does the same thing, but instead stores a Date object.

```ruby
# Usage: attr_time <method_name>, [options]
#        attr_date <method_name>, [options]
attr_time :created_at, default_proc: proc { Time.now }
attr_date :release_date, formats: ['%Y-%m-%d', '%Y/%m/%d']
```

The following arguments are available for attr_time and attr_date:
- __formats__: [Array of Strings] Formats allows for custom Time or Date formats to be used when parsing. These formats will be passed to the strptime method in order until one successfully creates a Time or Date object.

#### Simple Init

Simple Init is included in Effortless and provides an automatically constructed initialize method for all of the attr methods declared on the class. With Simple Init you will never need to write another initialize method again. How simple init interacts with BBLib::Attrs is described above but there are several other features showcased below.

```ruby
class Movie
  include BBLib::Effortless
  attr_str :title, arg_at: 0, required: true
  attr_str :description
  attr_int :duration
  attr_date :release_date
end

movie = Movie.new(title: 'Mad Max', duration: 96, release_date: '03-21-1980')
puts movie.title
# => Mad Max

# Since we added the :arg_at option to :title and told it to look for
# args at position 0, we can also pass the title as the first argument
# to the constructor without naming it.
movie = Movie.new('Toy Story 3')
puts movie.title
# => Toy Story 3

# We set the required: option to true on :title so SimpleInit will
# raise an exception if it is missing.
movie = Movie.new
# => ERROR: You are missing the following required argument for Movie: title (ArgumentError)

# By default if an attribute is passed in that does not exist (like :rating below)
# then an exception is thrown. This is due to the init_type which by default is set
# to :strict
movie = Movie.new(title: 'Up', rating: 'PG')
# => ERROR: Undefined attribute rating= for class Movie. (ArgumentError)

# Here we reopen the Movie class and set the init_type to :loose which will
# ignore unrecognized named arguments (and drop them).
# NOTE: :strict and :loose are the only two init_types.
class Movie
  init_type :loose
end

# Now rating no longer causes an error, and is instead ignored.
movie = Movie.new(title: 'Up', rating: 'PG')
puts movie.title
# => Up
```

#### Family Tree

Family Tree is another mixin that is built in to Effortless. It adds several methods that allow for the discovery of subclasses and instantiations of a class.

```ruby
class Animal
  include BBLib::Effortless
end

class Cat < Animal; end
class Dog < Animal; end

# Find all classes that inherit from Animal
p Animal.descendants
# => [Dog, Cat]

array = [Cat.new, Dog.new]

# Find all active instances of Animal or its descendants
p Animal.instances
# => [#<Dog:0x0000000005979118>, #<Cat:0x0000000005979820>]

class Calico < Cat; end
class Tabby < Cat; end

# Same as first call, but now we see the subclasses of our subclasses
p Animal.descendants
# => [Dog, Cat, Tabby, Calico]

# Similar to descendants but only shows classes that directly inherit from
# Animal and not their subclasses as well
p Animal.direct_descendants
# => [Dog, Cat]
```

NOTE: Family Tree can be added to classes without using Effortless by extending the BBLib::FamilyTree module.

#### Bridge

TODO

#### Hooks (before and after)

TODO

#### Serializer

TODO

### Hash Path

HashPath is a set of functions, classes and extensions to the native ruby hash and array classes. It allows items to be retrieved from a hash using a dot delimited syntax. It serves a similar function as XPath does for XML. It also provides methods for moving, copying and deleting paths within hashes as well as modifying the contents of nested paths with hashes.

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

### String Methods

Below are examples of the methods BBLib provides to the String class or for working with Strings.

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

### Numeric Methods

TODO

### OS / System Methods

TODO

### Time Methods

TODO

### Hash Methods

TODO

### Array Methods

TODO

### File Methods

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

### HTML Methods

TODO

### Logging

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bblack16/bblib. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

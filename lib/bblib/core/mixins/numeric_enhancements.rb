module BBLib
  # This module contains methods that are intended to be mixed in to
  # Integer and Float classes. They mostly provide convenience methods.
  module NumericEnhancements

    # Create a method for all types of times. Makes it easy
    # to convert to any range of seconds. e.g. 5.hours returns 3600
    TIME_EXPS.each do |name, data|
      [name, name.to_s.pluralize].each do |method|
        define_method(method) {
          (self * data[:mult]) / 1000
        }
      end
    end

    # Converts a number to english (only language supported currently)
    # For example, 501.spell_out returns 'five hundred and one'
    def spell_out(include_and: true)
      BBLib.number_spelled_out(self, include_and: include_and)
    end

    # Convert this integer into a string with every three digits separated by a delimiter
    # on the left side of the decimal
    def to_delimited_s(delim = ',')
      split = self.to_s.split('.')
      split[0] = split.first.reverse.gsub(/(\d{3})/, "\\1#{delim}").reverse
      split.join('.').uncapsulate(',')
    end

    # Returns the time x seconds ago from now (x == this number)
    def ago
      Time.now - self
    end

    # Returns the time x seconds ago from now (x == this number)
    def from_now
      Time.now + self
    end
  end

  Numeric.send(:include, NumericEnhancements)
end

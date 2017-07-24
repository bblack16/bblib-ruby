module BBLib
  # Used to apply multiple string comparison algorithms to strings and
  # normalize them to determine similarity for words or phrases.
  class FuzzyMatcher
    include Effortless
    attr_float_between 0, 100, :threshold, default: 75, serialize: true
    attr_bool :case_sensitive, default: true, serialize: true
    attr_bool :remove_symbols, :move_articles, :convert_roman, default: false, serialize: true
    attr_hash :algorithms, keys: [Symbol], values: [Float, Integer]

    # Calculates a percentage match between string a and string b.
    def similarity(string_a, string_b)
      string_a, string_b = prep_strings(string_a, string_b)
      return 100.0 if string_a == string_b
      score = 0
      total_weight = algorithms.values.inject { |sum, weight| sum + weight }
      algorithms.each do |algorithm, weight|
        next unless weight.positive?
        score+= string_a.send("#{algorithm}_similarity", string_b) * weight
      end
      score / total_weight
    end

    # Checks to see if the match percentage between Strings a and b are equal to or greater than the threshold.
    def match?(string_a, string_b)
      similarity(string_a, string_b) >= threshold.to_f
    end

    # Returns the best match from array b to string a based on percent.
    def best_match(string_a, *string_b)
      similarities(string_a, *string_b).max_by { |_k, v| v }[0]
    end

    # Returns a hash of array 'b' with the percentage match to a. If sort is true,
    # the hash is sorted desc by match percent.
    def similarities(string_a, *string_b)
      [*string_b].map { |word| [word, matches[word] = similarity(string_a, word)] }
    end

    def set_weight(algorithm, weight)
      return nil unless algorithms.include? algorithm
      algorithms[algorithm] = BBLib.keep_between(weight, 0, nil)
    end

    private

    def simple_setup
      self.algorithms = {
        levenshtein: 10,
        composition: 5,
        numeric:     0,
        phrase:      0
      }
    end

    def prep_strings(string_a, string_b)
      string_a = string_a.to_s.dup
      string_b = string_b.to_s.dup
      [
        case_sensitive? ? nil : :downcase,
        remove_symbols? ? :drop_symbols : nil,
        convert_roman? ? :from_roman : nil,
        move_articles? ? :move_articles : nil
      ].compact.each do |method|
        string_a = string_a.send(method)
        string_b = string_b.send(method)
      end
      [string_a, string_b]
    end
  end
end

module BBLib
  class FuzzyMatcher < LazyClass
    attr_float_between 0, 100, :threshold, default: 75, serialize: true
    attr_bool :case_sensitive, default: true, serialize: true
    attr_bool :remove_symbols, :move_articles, :convert_roman, default: false, serialize: true

    # Calculates a percentage match between string a and string b.
    def similarity(a, b)
      prep_strings a, b
      return 100.0 if @a == @b
      score = 0
      total_weight = @algorithms.map { |_alg, v| v[:weight] }.inject { |sum, w| sum += w }
      @algorithms.each do |_algo, vals|
        next unless vals[:weight].positive?
        score+= @a.send(vals[:signature], @b) * vals[:weight]
      end
      score / total_weight
    end

    # Checks to see if the match percentage between Strings a and b are equal to or greater than the threshold.
    def match?(a, b)
      similarity(a, b) >= @threshold.to_f
    end

    # Returns the best match from array b to string a based on percent.
    def best_match(a, b)
      similarities(a, b).max_by { |_k, v| v }[0]
    end

    # Returns a hash of array 'b' with the percentage match to a. If sort is true,
    # the hash is sorted desc by match percent.
    def similarities(a, b, sort: false)
      matches = {}
      [b].flatten.each { |m| matches[m] = similarity(a, m) }
      sort ? matches.sort_by { |_k, v| v }.reverse.to_h : matches
    end

    def set_weight(algorithm, weight)
      return nil unless @algorithms.include? algorithm
      @algorithms[algorithm][:weight] = BBLib.keep_between(weight, 0, nil)
    end

    def algorithms
      @algorithms.keys
    end

    private

    def lazy_setup
      @algorithms = {
        levenshtein: { weight: 10, signature: :levenshtein_similarity },
        composition: { weight: 5, signature: :composition_similarity },
        numeric:     { weight: 0, signature: :numeric_similarity },
        phrase:      { weight: 0, signature: :phrase_similarity }
        # FUTURE qwerty: {weight: 0, signature: :qwerty_similarity}
      }
    end

    def prep_strings(a, b)
      @a = a.to_s.dup
      @b = b.to_s.dup
      [
        @case_sensitive ? nil : :downcase,
        @remove_symbols ? :drop_symbols : nil,
        @convert_roman ? :from_roman : nil,
        @move_articles ? :move_articles : nil
      ].compact.each do |method|
        @a = @a.send(method)
        @b = @b.send(method)
      end
    end
  end
end

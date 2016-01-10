
module BBLib

  class FuzzyMatcher
    attr_reader :threshold
    attr_accessor :case_sensitive, :remove_symbols, :move_articles, :convert_roman

    def initialize threshold: 75, case_sensitive: true, remove_symbols: false, move_articles: false, convert_roman: true
      self.threshold = threshold
      @case_sensitive, @remove_symbols, @move_articles, @convert_roman = case_sensitive, remove_symbols, move_articles, convert_roman
    end

    # Calculates a percentage match between string a and string b.
    def similarity a, b
      return 100.0 if a == b
      prep_strings a, b
      score, total_weight = 0, ALGORITHMS.map{|a, v| v[:weight] }.inject{ |sum, w| sum+=w }
      ALGORITHMS.each do |algo, vals|
        next unless vals[:weight] > 0
        score+= @a.send(vals[:signature], @b) * vals[:weight]
      end
      score / total_weight
    end

    # Checks to see if the match percentage between Strings a and b are equal to or greater than the threshold.
    def match? a, b
      similarity(a, b) >= @threshold.to_f
    end

    # Returns the best match from array b to string a based on percent.
    def best_match a, b
      similarities(a, b).max_by{ |k, v| v}[0]
    end

    # Returns a hash of array 'b' with the percentage match to a. If sort is true, the hash is sorted desc by match percent.
    def similarities a, b, sort: false
      matches = Hash.new
      [b].flatten.each{ |m| matches[m] = self.similarity(a, m) }
      sort ? matches.sort_by{ |k, v| v }.reverse.to_h : matches
    end

    def threshold= threshold
      @threshold = BBLib.keep_between(threshold, 0, 100)
    end

    def set_weight algorithm, weight
      return nil unless ALGORITHMS.include? algorithm
      ALGORITHMS[algorithm] = BBLib.keep_between(weight, 0, nil)
    end

    def algorithms
      ALGORITHMS.keys
    end

    private

      ALGORITHMS = {
        levenshtein: {weight: 10, signature: :levenshtein_similarity},
        composition: {weight: 5, signature: :composition_similarity},
        numeric: {weight: 0, signature: :numeric_similarity},
        phrase: {weight: 0, signature: :phrase_similarity},
        qwerty: {weight: 0, signature: :qwerty_similarity}
      }

      def prep_strings a, b
        @a, @b = a.to_s.dup.strip, b.to_s.dup.strip
        if !@case_sensitive then @a.downcase!; @b.downcase! end
        if @remove_symbols then @a.drop_symbols!; @b.drop_symbols! end
        if @convert_roman then @a.from_roman!; @b.from_roman! end
        if @move_articles then @a.move_articles!(:front, @case_sensitive); @b.move_articles! :front, @case_sensitive end
      end

  end

end

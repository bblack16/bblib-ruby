
module BBLib

  class FuzzyMatcher
    attr_reader :weights
    attr_reader :threshold, :levenshtein_weight, :composition_weight, :numeric_weight, :phrase_weight, :qwerty_weight
    attr_accessor :case_sensitive, :remove_symbols, :move_articles, :convert_roman

    def initialize threshold: 75, case_sensitive: true, remove_symbols: false, move_articles: false, convert_roman: true
      set_threshold 75
      @levenshtein_weight, @composition_weight, @numeric_weight, @phrase_weight, @qwerty_weight = 10, 5, 1, 1, 0
    end

    def similarity a, b
      prep_strings a, b
      # return 100 unless @a != @b
      score = 0
      total_weight = @levenshtein_weight + @composition_weight + @numeric_weight + @phrase_weight
      puts "Leven:   #{@a.levenshtein_similarity(@b)}"
      puts "Comp:    #{@a.composition_similarity(@b)}"
      puts "Numeric: #{@a.numeric_similarity(@b)}"
      puts "Phrase:  #{@a.phrase_similarity(@b)}"
      if @levenshtein_weight > 0 then score+= @levenshtein_weight * @a.levenshtein_similarity(@b) end
      if @composition_weight > 0 then score+= @composition_weight * @a.composition_similarity(@b) end
      if @numeric_weight > 0 then score+= @numeric_weight * @a.numeric_similarity(@b) end
      if @phrase_weight > 0 then score+= @phrase_weight * @a.phrase_similarity(@b) end
      # Not yet supported -- if @qwerty_weight > 0 then score+= @qwerty_weight * @a.qwerty_similarity(@b) end
      score / total_weight
    end

    def match? a, b
      similarity(a, b) >= @threshold.to_f
    end

    def set_threshold threshold
      @threshold = threshold.to_i.between?(1,100) ? threshold.to_i : 75
    end

    private
      @a, @b = String.new, String.new

      MATCH_TYPES = [
        :levenshtein, :composition, :numeric_weight, :phrase_weight, :qwerty
      ]

      def prep_strings a, b
        @a, @b = a.dup.strip, b.dup.strip
        if !@case_sensitive
          @a.downcase!
          @b.downcase!
        end
        if @remove_symbols
          @a.drop_symbols!
          @b.drop_symbols!
        end
        if @convert_roman
          @a.from_roman!
          @b.from_roman!
        end
        if @move_articles
          @a.move_articles! :front, @case_sensitive
          @b.move_articles! :front, @case_sensitive
        end
      end

  end

end

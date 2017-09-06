

module BBLib

  SPECIAL_PLURALS = {
    addendum: :addenda,
    alga: :algae,
    alumnus: :alumni,
    amoeba: :amoebae,
    analysis: :analyses,
    antenna: :antennae,
    appendix: :appendices,
    auto: :autos,
    axis: :axes,
    bacterium: :bacteria,
    barracks: :barracks,
    basis: :bases,
    cactus: :cacti,
    calf: :calves,
    crisis: :crises,
    curriculum: :curricula,
    datum: :data,
    deer: :deer,
    diagnosis: :diagnoses,
    echo: :echoes,
    elf: :elves,
    ellipsis: :ellipses,
    embargo: :embargoes,
    emphasis: :emphases,
    fish: :fish,
    foot: :feet,
    fungus: :fungi,
    gallows: :gallows,
    genus: :genera,
    goose: :geese,
    half: :halves,
    hero: :heroes,
    hoof: :hooves,
    hypothesis: :hypotheses,
    index: :indices,
    kangaroo: :kangaroos,
    kilo: :kilos,
    knife: :knives,
    larva: :larvae,
    leaf: :leaves,
    life: :lives,
    loaf: :loaves,
    louse: :lice,
    man: :men,
    matrix: :matrices,
    means: :means,
    memo: :memos,
    memorandum: :memoranda,
    mouse: :mice,
    neurosis: :neuroses,
    oasis: :oases,
    offspring: :offspring,
    paralysis: :paralyses,
    parenthesis: :parentheses,
    person: :people,
    photo: :photos,
    piano: :pianos,
    pimento: :pimentos,
    potato: :potatoes,
    pro: :pros,
    self: :selves,
    series: :series,
    sheep: :sheep,
    shelf: :shelves,
    solo: :solos,
    soprano: :sopranos,
    species: :species,
    stimulus: :stimuli,
    studio: :studios,
    syllabus: :syllabi,
    tattoo: :tattoos,
    thesis: :theses,
    thief: :thieves,
    tomato: :tomatoes,
    tooth: :teeth,
    torpedo: :torpedoes,
    vertebra: :vertebrae,
    veto: :vetoes,
    video: :videos,
    wife: :wives,
    wolf: :wolves,
    woman: :women,
    zoo: :zoos
  }

  def self.pluralize(string, num = 2)
    full_string = string.to_s
    string = string.split(/\s+/).last
    sym = string.to_s.downcase.to_sym
    if plural = SPECIAL_PLURALS[sym]
      result = num == 1 ? string : plural
    else
      if string.end_with?(*%w{ch z s x o})
        result = num == 1 ? string : (string + 'es')
      elsif string =~ /[^aeiou]y$/i
        result = num == 1 ? string : string.sub(/y$/i, 'ies')
      else
        result = num == 1 ? string : (string + 's')
      end
    end
    full_string.sub(/#{Regexp.escape(string)}$/, copy_capitalization(string, result).to_s)
  end

  def self.singularize(string)
    full_string = string.to_s
    string = string.split(/\s+/).last
    sym = string.to_s.downcase.to_sym
    sym = string.to_s.downcase.to_sym
    if singular = SPECIAL_PLURALS.find { |k, v| v == sym }&.first
      result = singular
    elsif string.downcase.end_with?(*%w{oes ches zes ses xes})
      result = string.sub(/es$/i, '')
    elsif string =~ /ies$/i
      result = string.sub(/ies$/i, 'y')
    elsif string =~ /s$/i && !(string =~ /s{2}$/i)
      result = string.sub(/s$/i, '')
    else
      result = string
    end
    full_string.sub(/#{Regexp.escape(string)}$/, copy_capitalization(string, result).to_s)
  end

  def self.custom_pluralize(num, base, plural = 's', singular = nil)
    num == 1 ? "#{base}#{singular}" : "#{base}#{plural}"
  end

  def self.plural_string(num, *args)
    "#{num} #{pluralize(num, *args)}"
  end

end

class String
  def pluralize(num = 2)
    BBLib.pluralize(self, num)
  end

  def singularize
    BBLib.singularize(self)
  end
end

class Symbol
  def pluralize(num = 2)
    BBLib.pluralize(self.to_s, num).to_sym
  end

  def singularize
    BBLib.singularize(self.to_s).to_sym
  end
end

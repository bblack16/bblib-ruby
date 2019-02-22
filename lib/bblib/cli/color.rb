module BBLib
  module Console

    COLOR_CODES = {
      black:   30,
      red:     31,
      green:   32,
      orange:  33,
      yellow:  33,
      blue:    34,
      purple:  35,
      cyan:    36,
      gray:    37,
      grey:    37,
      white:   37,
      none:    0,
      default: 39
    }.freeze

    SEVERITY_COLORS = {
      debug:   :light_purple,
      info:    :light_blue,
      warn:    :yellow,
      error:   :light_red,
      fatal:   :red,
      success: :green,
      ok:      :green,
      fail:    :red
    }

    def self.colorize(text, color = :none, background: false, light: false)
      color = SEVERITY_COLORS[color.to_s.downcase.to_sym] if SEVERITY_COLORS.include?(color.to_s.downcase.to_sym)
      if color.to_s.start_with?('light_')
        color = color.to_s.split('_', 2).last.to_sym
        light = true
      end
      light = true if color == :grey || color == :gray
      color = COLOR_CODES[color] if COLOR_CODES.include?(color)
      color = COLOR_CODES[:default] unless color.is_a?(Integer)
      color += 10 if background
      "\e[#{light ? 1 : 0};#{color}m#{text}\e[0m"
    end

  end
end

class String
  def to_color(color_code, opts = {})
    BBLib::Console.colorize(self, color_code, **opts)
  end
end

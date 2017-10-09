module BBLib
  module HTML
    class Tag
      include BBLib::Effortless
      include Builder

      attr_str :type, required: true, arg_at: 0, arg_at_accept: [String, Symbol]
      attr_str :content, arg_at: 1, arg_at_accept: [String, Symbol]
      attr_hash :attributes, default: {}
      attr_ary_of Tag, :children, default: []
      attr_of Object, :context, default: nil, allow_nil: true

      def render(pretty: false, tabs: 0)
        cont = render_content(pretty: pretty, tabs: tabs)
        tabbing = pretty ? ("\n" + ("\t" * tabs)) : ''
        "#{tabbing}<#{type}#{render_attributes}" +
        if cont || !BBLib::HTML.self_close?(type)
          ">#{cont}#{tabbing}</#{type}>"
        else
          "/>"
        end
      end

      def to_s
        render
      end

      def to_str
        to_s
      end

      def render_attributes
        return nil if attributes.empty?
        styles = attributes[:style] ? { style: attributes[:style].map { |k, v| "#{k}: #{v}" }.join('; ') } : {}
        ' ' + attributes.merge(styles).map { | k, v| "#{k}=\"#{v.to_s.gsub('"', '&#34;')}\"" }.join(' ')
      end

      def render_content(pretty: false, tabs: 0)
        return nil if (content.nil? || content.empty?) && children.empty?
        tabbing = pretty ? ("\n" + ("\t" * (tabs + 1))) : ''
        text = if content && !content.empty?
          "#{tabbing}#{content.gsub("\n", tabbing)}"
        end
        html = children.map { |tag| tag.render(pretty: pretty, tabs: tabs + 1) }.join
        [text, html].compact.join
      end
    end
  end
end

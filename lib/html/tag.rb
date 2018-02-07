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

      init_type :loose

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

      alias to_html render

      def add(*childs)
        [childs].flatten.map { |child| children.push(child) }
      end

      def to_s(*args)
        render(*args)
      end

      def to_str
        to_s
      end

      def render_attributes
        return nil if attributes.empty?
        attributes[:style] = attributes[:style].map { |k, v| "#{k}: #{v}" }.join('; ') if attributes[:style] && attributes[:style].is_a?(Hash)
        ' ' + attributes.map do | k, v|
          v = v.join(' ') if v.is_a?(Array)
          "#{k}=\"#{v.to_s.gsub('"', '&#34;')}\""
        end.join(' ')
      end

      def render_content(pretty: false, tabs: 0)
        return nil if (content.nil? || content.empty?) && children.empty?
        tabbing = pretty ? ("\n" + ("\t" * (tabs + 1))) : ''
        text = if content && !content.empty?
          "#{tabbing}#{content.gsub("\n", pretty ? tabbing : "\n")}"
        end
        html = children.map { |tag| tag.render(pretty: pretty, tabs: tabs + 1) }.join
        [text, html].compact.join
      end

      protected

      def simple_init(*args)
        BBLib.named_args(*args).each do |k, v|
          next if _attrs.include?(k)
          self.attributes[k] = v
        end
      end

      def method_missing(method, *args, &block)
        if context && context.respond_to?(method)
          context.send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        super || context && context.respond_to?(method)
      end
    end
  end
end

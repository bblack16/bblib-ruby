module BBLib
  module HTML
    class Tag
      include BBLib::Effortless
      include Builder

      APPEND_ATTRIBUTES = [:class, :style].freeze

      attr_str :type, required: true, arg_at: 0, arg_at_accept: [String, Symbol]
      attr_str :content, default: nil, allow_nil: true, arg_at: 1, arg_at_accept: [String, Symbol]
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
        [childs].flatten.each { |child| children.push(child) }
        nil
      end

      def to_s(*args)
        render(*args)
      end

      def to_str
        to_s
      end

      def set_attribute(attribute, value)
        attributes[attribute] = value
      end

      def append_attribute(attribute, value)
        attributes[attribute] = [attributes[attribute], value.to_s].compact.join(' ')
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

      def merge(attributes)
        raise ArgumentError, "Expected a Hash, got a #{attributes.class}" unless attributes.is_a?(Hash)
        attributes.each do |k, v|
          if APPEND_ATTRIBUTES.include?(k.to_sym)
            append_attribute(k, v)
          else
            set_attribute(k, v)
          end
        end
        self
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
        elsif method != :to_ary
          if method.to_s.encap_by?('_')
            self.set_attribute(:id, method.to_s.uncapsulate('_'))
          else
            klass = method.to_s.gsub(/(?<=[^\_])\_(?=[^\_])/, '-').gsub('__', '_')
            self.append_attribute(:class, klass)
          end
          self._initialize(type, *args, &block)
          self
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        super || context && context.respond_to?(method)
      end

      def simple_init_block_result(value)
        return false unless value && content.nil? && !value.is_a?(Tag)
        self.content = value.to_s
      end
    end
  end
end

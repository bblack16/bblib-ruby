module BBLib
  module HTML
    TAGS = %w{a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col colgroup command datalist dd del details dfn div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd keygen label legend li link map mark menu meta meter nav noscript object ol optgroup option output p param pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr}

    SELF_CLOSING_TAGS = %w{area base br col command embed hr img input keygen link meta param source track wbr}

    def self.self_close?(tag)
      SELF_CLOSING_TAGS.include?(tag.to_s.downcase)
    end

    def self.build(*args, &block)
      Builder.build(*args, &block)
    end

    module Builder

      BBLib::HTML::TAGS.each do |tag|
        define_method(tag) do |content = nil, **attributes, &block|
          context = attributes.delete(:context) || self.context
          Tag.new(type: tag, attributes: attributes, content: content, context: context).tap do |t|
            children << t
            t.instance_eval(&block) if block
          end
        end
      end

      def build(&block)
        instance_eval(&block)
        self
      end

      def self.build(type = nil, content = nil, **attributes, &block)
        raise ArgumentError, "Unknown element type '#{type}'." unless TAGS.include?(type.to_s.downcase) || type == nil
        context = attributes.delete(:context)
        if type
          Tag.new(type: type, attributes: attributes, content: content, context: context, &block)
        else
          TagSet.new(attributes: attributes, context: context, &block)
        end
      end
    end
  end
end

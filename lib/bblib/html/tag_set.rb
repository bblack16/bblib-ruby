module BBLib
  module HTML
    # Similar to the default tag but isn't representative of a an HTML element.
    # Instead, this is a collection of nested HTML Elements, so only children of
    # TagSets are rendered to html.
    class TagSet < Tag
      attr_str :type, required: false, default: nil, allow_nil: true

      def render(pretty: false, tabs: 0)
        render_content(pretty: pretty, tabs: tabs)
      end

      def render_content(pretty: false, tabs: 0)
        return '' if children.empty?
        children.map { |tag| tag.render(pretty: pretty, tabs: tabs + 1) }.join
      end

    end
  end
end

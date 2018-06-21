require File.join File.expand_path('../../', __FILE__), 'helpers/var'

module LiquidPlus
  class ReturnTag < Liquid::Tag

    def initialize(tag_name, markup, parse_context)
      @markup = markup.strip
      @parse_context = parse_context
      super
    end

    def parse(_tokens)
    end

    def render(context)
      if parsed_markup = Conditional.parse(@markup, context)
        Var.get_value(parsed_markup, context, @parse_context)
      else
        ''
      end
    end
  end
end


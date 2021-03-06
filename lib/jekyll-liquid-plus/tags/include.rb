require File.join File.expand_path('../../', __FILE__), 'helpers/path'
require File.join File.expand_path('../../', __FILE__), 'helpers/cache'

module Jekyll

  # Create a new page class to allow partials to trigger Jekyll Page Hooks.
  class ConvertiblePage
    include Convertible
    
    attr_accessor :name, :content, :site, :ext, :output, :data
    
    def initialize(site, name, content)
      @site     = site
      @name     = name
      @ext      = File.extname(name)
      @content  = content
      @data     = { layout: "no_layout" } # hack
      
    end
    
    def render(payload)
      do_layout(payload, { no_layout: nil })
    end
  end
end

module LiquidPlus
  class IncludeTag < Jekyll::Tags::IncludeTag
    LOCALS = /(.*?)(([\w-]+)\s*=\s*(?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w\.-]+)))(.*)?/

    alias_method :default_render, :render


    def initialize(tag_name, markup, tokens)
      @tag = tag_name.strip
      @markup = markup.strip
      # If raw, strip from the markup as not to confuse the Path syntax parsing
      if @markup =~ /^(\s*raw\s)?(.+?)(\sraw\s*)?$/
        @markup = $2.strip
        @raw = true unless $1.nil? and $3.nil?
      end

      split_params
    end
    
    def render(context)
      validate_params if @params
      @file = get_path(context)
      if @tag == 'include' && @file && Cache.exists(Path.expand(File.join(INCLUDES_DIR, @file), context))
        include_tag(context)
      elsif @tag =~ /render/ && @file && Cache.exists(@file)
        render_tag(context)
      elsif @file
        not_found(context)
      end
    end

    def include_tag(context)
      @markup = @file
      @markup += @params if @params
      @page = context.registers[:page]['path']
      content = default_render(context)
      parse_convertible(content, context)
    end

    def render_tag(context)
      @markup = @file
      @markup += @params if @params
      content = read_raw

      unless @raw
        partial = Liquid::Template.parse(content)

        content = context.stack do
          context['render'] = Jekyll::Tags::IncludeTag.new('include', @markup, []).parse_params(context) if @params
          context['page'] = context['page'].deep_merge(@local_vars) if @local_vars and @local_vars.keys.size > 0
          partial.render!(context)
        end
        content = parse_convertible(content, context)
      end
      content
    end

    def not_found(context)
      @file = File.join(INCLUDES_DIR, @file) if @tag == 'include'
      name = File.basename(@file)
      dir  = @file.to_s.sub(context.registers[:site].source + '/', '').sub(name, '')
      msg = "File '#{name}' not found"
      msg +=  " in '#{dir}'" if dir.length > 0 && name != dir
      raise IOError.new msg
    end

    def parse_convertible(content, context)
      page = Jekyll::ConvertiblePage.new(context.registers[:site], @file, content)
      page.render({})
      content = page.output.strip
    end

    def split_params
      if @markup =~ LOCALS
        @params = ' ' + $2
        @markup = $1 + $7
      end
    end

    def get_path(context)
      root = (@tag == 'include') ? INCLUDES_DIR : nil
      if file = Path.parse(@markup, context, root)
        file = Path.expand(file, context) if @tag =~ /render/
        @markup = file
        file
      end
    end

    #Strip out yaml header from partials
    def strip_yaml(content)
      if content =~ /\A-{3}(.+[^\A])-{3}\n(.+)/m
        $2.strip
      end
      content
    end

    def read_raw
      path = Pathname.new @file
      Dir.chdir(File.dirname(path)) do
        content = path.read
        if content =~ /\A-{3}(.+[^\A])-{3}\n(.+)/m
          @local_vars = YAML.safe_load($1.strip)
          content = $2.strip
        end
        content
      end
    end
  end
end




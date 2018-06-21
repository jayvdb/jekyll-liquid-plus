require 'liquid'
require 'jekyll'

$:.unshift File.dirname(__FILE__)

$LOAD_PATH.unshift(File.dirname(__FILE__))

module LiquidPlus
  autoload :Cache,         'jekyll-liquid-plus/helpers/cache'
  autoload :WrapTag,       'jekyll-liquid-plus/tags/wrap'
  autoload :ReturnTag,     'jekyll-liquid-plus/tags/return'
end

Liquid::Template.register_tag('wrap', LiquidPlus::WrapTag)
Liquid::Template.register_tag('wrap_include', LiquidPlus::WrapTag)
Liquid::Template.register_tag('return', LiquidPlus::ReturnTag)


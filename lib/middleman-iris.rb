require "middleman-iris/version"
require "middleman-core"

::Middleman::Extensions.register( :iris ) do
   require 'middleman-iris/extension'
   ::Middleman::Iris::IrisExtension
end

class Hola
  def self.hi
    puts "Hello world!"
  end
end

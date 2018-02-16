require "middleman-core"
require "middleman-iris/version"
require 'middleman-vcs-time'

::Middleman::Extensions.register( :iris ) do
   require 'middleman-iris/extension'
   ::Middleman::Iris::IrisExtension
end

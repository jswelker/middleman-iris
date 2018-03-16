require File.expand_path("../../lib/middleman-iris", __FILE__)
require File.expand_path("../../lib/middleman-iris/extension", __FILE__)

ENV['MM_ROOT'] = File.expand_path('../../fixtures/default-app', __FILE__)
ENV['MM_ENV'] = 'test'

@app = ::Middleman::Application.new do
  ::Middleman::Logger.singleton(1, false)
  config[:watcher_disable] = true
end

RSpec.configure do |config|

end

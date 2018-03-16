require 'bundler'
Bundler::GemHelper.install_tasks

require 'cucumber/rake/task'

require 'middleman-core'

Cucumber::Rake::Task.new( :cucumber, 'Run features that should pass' ) do | t |
  ENV[ "TEST" ] = "true"
  t.cucumber_opts = "--color --strict --format #{ ENV[ 'CUCUMBER_FORMAT' ] || 'pretty' }"
end

require 'rake/clean'

desc "Run tests, both RSpec and Cucumber"
task test: [ :spec, :cucumber ]

require 'rspec/core/rake_task'

desc "Run RSpec"

RSpec::Core::RakeTask.new do | spec |
  spec.pattern    = 'spec/**/*_spec.rb'
  spec.rspec_opts = [ '--color', '--format documentation' ]
end

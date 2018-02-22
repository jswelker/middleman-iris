module Middleman::Cli
  class GenerateIndex < Thor::Group
    include Thor::Actions

    check_unknown_options!

    def generate_index
      start_time = Time.now
      puts "Starting generate_index at #{Time.now}"

      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :index
        ::Middleman::Logger.singleton(1, false)
      end

      # Middleman::Sitemap::Resource.build_index(@app)
      puts "Finished generate_index at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_index', 'generate_index', 'Build search index for the Middleman IRIS application')
  end
end

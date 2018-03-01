module Middleman::Cli
  class GenerateOai < Thor::Group
    include Thor::Actions

    check_unknown_options!

    def generate_oai
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :oai
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting generate_oai at #{Time.now}"

      Middleman::Sitemap::Resource.generate_oai(@app)

      puts "Finished generate_oai at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_oai', 'generate_oai', 'Build OAI-PMH Static Repository for the Middleman IRIS application')
  end
end

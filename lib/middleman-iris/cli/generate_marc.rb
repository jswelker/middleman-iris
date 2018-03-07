module Middleman::Cli
  class GenerateMarc < Thor::Group
    include Thor::Actions

    check_unknown_options!

    def generate_marc
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :marc
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting generate_marc at #{Time.now}"

      Middleman::Sitemap::Resource.generate_marc(@app)

      puts "Finished generate_rdf at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_marc', 'generate_marc', 'Build RDF files for the Middleman IRIS application')
  end
end

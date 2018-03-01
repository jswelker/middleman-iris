module Middleman::Cli
  class GenerateRdf < Thor::Group
    include Thor::Actions

    check_unknown_options!

    def generate_rdf
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :rdf
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting generate_rdf at #{Time.now}"

      Middleman::Sitemap::Resource.generate_rdf(@app)

      puts "Finished generate_rdf at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_rdf', 'generate_rdf', 'Build RDF files for the Middleman IRIS application')
  end
end

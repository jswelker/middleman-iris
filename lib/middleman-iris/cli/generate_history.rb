module Middleman::Cli
  class GenerateHistory < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :directory,
                default: nil,
                desc: 'A specific directory for which to generate history.'

    def generate_history
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :history
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting generate_history at #{Time.now}"

      Middleman::Sitemap::Resource.generate_history(@app.sitemap.resources)

      puts "Finished generate_history at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_history', 'generate_history [options]', 'Build file histories for the Middleman IRIS application')
  end
end

module Middleman::Cli
  class GenerateRss < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :limit,
                default: 100,
                desc: 'Number of items to show in RSS feed.'

    def generate_rss
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :rss
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting generate_rss at #{Time.now}"

      Middleman::Sitemap::Resource.generate_rss(@app, options[:limit].to_i)

      puts "Finished generate_rss at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_rss', 'generate_rss [options]', 'Build rss feed for the Middleman IRIS application')
  end
end

module Middleman::Cli
  module Generators


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

        Middleman::Sitemap::Resource.generate_history(@app, options[:directory])

        puts "Finished generate_history at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'generate_history', 'generate_history [options]', 'Build file histories for the Middleman IRIS application')
    end



    class ClearHistory < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :directory,
                  default: nil,
                  desc: 'A specific directory for which to clear history.'

      def clear_history
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :history
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting clear_history at #{Time.now}"

        Middleman::Sitemap::Resource.clear_history(@app, options[:directory])

        puts "Finished clear_history at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'clear_history', 'clear_history [options]', 'Clear file histories for the Middleman IRIS application')
    end



    class GenerateText < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :regenerate,
                  default: false,
                  desc: 'Whether to regenerate text that already exists.'
      class_option :directory,
                  default: nil,
                  desc: 'A specific directory for which to generate text.'

      def generate_text
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :text
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting generate_text at #{Time.now}"

        Middleman::Sitemap::Resource.generate_text(@app, options[:directory], options[:regenerate])

        puts "Finished generate_text at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'generate_text', 'generate_text [options]', 'Build text for indexing for the Middleman IRIS application')
    end


    class ClearText < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :directory,
                  default: nil,
                  desc: 'A specific directory for which to clear text.'

      def clear_text
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :text
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting clear_text at #{Time.now}"

        Middleman::Sitemap::Resource.clear_text(@app, options[:directory])

        puts "Finished clear_text at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'clear_text', 'clear_text [options]', 'Clear text for indexing for the Middleman IRIS application')
    end


    class GenerateThumbnails < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :regenerate,
                  default: false,
                  desc: 'Whether to regenerate thumbnails that already exist.'
      class_option :directory,
                  default: nil,
                  desc: 'A specific directory for which to generate thumbnails.'

      def generate_thumbnails
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :thumbnails
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting generate_thumbnails at #{Time.now}"

        Middleman::Sitemap::Resource.generate_thumbnails(@app, options[:directory], options[:regenerate])

        puts "Finished generate_thumbnails at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'generate_thumbnails', 'generate_thumbnails [options]', 'Build thumbnails for the Middleman IRIS application')
    end


    class ClearThumbnails < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :directory,
                  default: nil,
                  desc: 'A specific directory for which to clear thumbnails.'

      def clear_thumbnails
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :thumbnails
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting clear_thumbnails at #{Time.now}"

        Middleman::Sitemap::Resource.generate_thumbnails(@app, options[:directory])

        puts "Finished clear_thumbnails at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'clear_thumbnails', 'clear_thumbnails [options]', 'Clear thumbnails for the Middleman IRIS application')
    end



    class GenerateIndex < Thor::Group
      include Thor::Actions

      check_unknown_options!

      def generate_index
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :index
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting generate_index at #{Time.now}"

        Middleman::Sitemap::Resource.generate_index(@app)

        puts "Finished generate_index at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'generate_index', 'generate_index', 'Build search index for the Middleman IRIS application')
    end


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
end

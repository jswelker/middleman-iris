module Middleman::Cli
  module Validators


    class ValidateDuplicateUris < Thor::Group
      include Thor::Actions

      check_unknown_options!

      class_option :directory,
                  default: nil,
                  desc: 'A specific directory in which to look for the properties.'


      def validate_duplicate_uris
        @app = ::Middleman::Application.new do
          config[:mode] = :build
          config[:iris_cli] = :validate_duplicate_uris
          ::Middleman::Logger.singleton(1, false)
        end

        start_time = Time.now
        puts "Starting validate_duplicate_uris at #{Time.now}"

        Middleman::Sitemap::Resource.validate_duplicate_uris(app, options[:directory])

        puts "Finished validate_duplicate_uris at #{Time.now} (#{Time.now-start_time} seconds)"
      end

      Base.register(self, 'validate_duplicate_uris', 'validate_duplicate_uris [options]', 'Check resources to see if any share the same URI')
    end
  end



  class ValidatMissingProperties < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :properties,
                required: true,
                default: nil,
                desc: 'The properties to look for.'

    class_option :directory,
                default: nil,
                desc: 'A specific directory in which to look for the properties.'

    class_option :static_files,
                default: false,
                desc: 'Whether to check static files for the properties rather than just parent items.'


    def validate_missing_properties
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :validate_missing_properties
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting validate_missing_properties at #{Time.now}"

      properties = [options[:properties]].flatten
      Middleman::Sitemap::Resource.validate_missing_properties(app, properties, options[:directory], options[:static_files], true)

      puts "Finished validate_missing_properties at #{Time.now} (#{Time.now-start_time} seconds)"
    end


    Base.register(self, 'validate_missing_properties', 'validate_missing_properties [options]', 'Check items to see which are missing a specific RDF metadata property')
  end


  class ValidateHttpErrorUris < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :directory,
                default: nil,
                desc: 'A specific directory in which to look for files containing 404 URIs.'


    def validate_http_error_uris
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :validate_http_error_uris
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting validate_http_error_uris at #{Time.now}"

      Middleman::Sitemap::Resource.validate_http_error_uris(app, options[:directory])

      puts "Finished validate_http_error_uris at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'validate_http_error_uris', 'validate_http_error_uris [options]', 'Check resources to see if any point to a URI with an HTTP error code like 404')
  end


end

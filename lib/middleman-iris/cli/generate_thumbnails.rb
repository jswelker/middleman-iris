module Middleman::Cli
  class GenerateThumbnails < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :regenerate,
                aliases: '-e',
                default: false,
                desc: 'Whether to regenerate thumbnails that already exist.'
    class_option :directory,
                aliases: '-e',
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
      
      resources = @app.sitemap.resources
      if options[:directory].present?
        resources = resources.select{|r| r.source_file.downcase.start_with?(options[:directory].downcase)}
      end
      Middleman::Sitemap::Resource.generate_thumbnails(resources, options[:regenerate])

      puts "Finished generate_thumbnails at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_thumbnails', 'generate_thumbnails [options]', 'Build thumbnails for the Middleman IRIS application')
  end
end

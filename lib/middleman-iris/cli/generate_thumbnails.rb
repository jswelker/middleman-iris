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
      start_time = Time.now
      puts "Starting generate_thumbnails at #{Time.now}"

      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :thumbnails
        ::Middleman::Logger.singleton(1, false)
      end

      # @app.sitemap.resources.each do |r|
      #   next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
      #   next if !options[:regenerate] && r.thumbnail?
      #   next if options[:directory] && !r.dirname.start_with?(options[:directory])
      #   r.generate_thumbnail
      # end
      puts "Finished generate_thumbnails at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_thumbnails', 'generate_thumbnails [options]', 'Build thumbnails for the Middleman IRIS application')
  end
end

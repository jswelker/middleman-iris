module Middleman::Cli
  class GenerateText < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :regenerate,
                aliases: '-e',
                default: false,
                desc: 'Whether to regenerate text that already exists.'
    class_option :directory,
                aliases: '-e',
                default: nil,
                desc: 'A specific directory for which to generate text.'

    def generate_text
      start_time = Time.now
      puts "Starting generate_text at #{Time.now}"
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :text
        ::Middleman::Logger.singleton(1, false)
      end

      # @app.sitemap.resources.each do |r|
      #   next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
      #   next if r.text.present? && !options[:regenerate]
      #   next if options[:directory] && !r.dirname.start_with?(options[:directory])
      #   r.generate_text
      # end
      puts "Finished generate_text at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_text', 'generate_text [options]', 'Build text for indexing for the Middleman IRIS application')
  end
end

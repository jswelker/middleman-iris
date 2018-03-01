module Middleman::Cli
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

      resources = @app.sitemap.resources
      if options[:directory].present?
        resources = resources.select{|r| r.source_file.start_with?(options[:directory])}
      end
      Middleman::Sitemap::Resource.generate_text(resources, options[:regenerate])

      puts "Finished generate_text at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_text', 'generate_text [options]', 'Build text for indexing for the Middleman IRIS application')
  end
end

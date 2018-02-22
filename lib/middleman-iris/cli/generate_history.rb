module Middleman::Cli
  class GenerateHistory < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :directory,
                aliases: '-e',
                default: nil,
                desc: 'A specific directory for which to generate history.'

    def generate_history
      start_time = Time.now
      puts "Starting generate_history at #{Time.now}"

      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :history
        ::Middleman::Logger.singleton(1, false)
      end

      # @app.sitemap.resources.each do |r|
      #   next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
      #   next if options[:directory] && !r.dirname.start_with?(options[:directory])
      #   r.add_file_history
      # end
      puts "Finished generate_history at #{Time.now} (#{Time.now-start_time} seconds)"
    end

    Base.register(self, 'generate_history', 'generate_history [options]', 'Build file histories for the Middleman IRIS application')
  end
end

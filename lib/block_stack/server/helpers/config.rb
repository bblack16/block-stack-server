module BlockStack
  module Helpers
    module Config
      # Load every config file from all config directories that match the given
      # config patterns.
      def load_configs
        return false if config.config_folders.empty? || config.config_patterns.empty?
        config.config_folders.each do |dir|
          logger.info("Searching for configuration files in #{dir}.")
          BBLib.scan_files(dir, *config.config_patterns) do |file|
            load_config(file)
          end
        end
      end

      # Load a given config file at a path on disk. Can be JSON or YML
      def load_config(path)
        name = file.file_name(false).to_sym
        custom_loader = "load_#{name}_config"
        if respond_to?(custom_loader)
          send(custom_loader, path)
        else
          config(name => Harmoni.build(file, sync: config.sync_configs))
          logger.info("Successfully loaded config file #{name} (#{path})")
        end
      rescue StandardError => e
        logger.error("Failed to load config file at #{path}: #{e}")
        raise e
      end

      # Load the application config for the current environment.
      def load_application_config(path)
        logger.debug("Loading application configuration from #{path}")
        config = Harmoni.build(path)
        config = config.except(:environment).merge(config[environment] || {})
        (config.settings || {}).each { |k, v| set(k, v) }
        (config.config || {}).each { |k, v| config(k, v) }
        true
      end

      # Loader to build databases from a yml config file
      def load_database_config(path)
        logger.info("Loading database(s) from config at #{path}")
        config = Harmoni.build(path)
        databases = [config[environment], config[:default]].flatten(1).compact
        databases.each do |db|
          BlockStack::Database.setup(db[:name], db[:adapter], *[db[:configuration]].flatten(1))
        end
        true
      end
    end
  end
end

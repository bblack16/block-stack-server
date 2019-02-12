module BlockStack
  class Server < Sinatra::Base

    # Set or retrieve configuration variables or the entire config object.
    def self.config(args = nil)
      case args
      when Hash
        configuration.set(args)
      when String, Symbol
        configuration.to_h.hpath(args).first
      when nil
        configuration
      else
      end
    end

    # Loads the configuration of an ancestors this class inherits from.
    def self.inherited_config
      ancestors.reverse.each_with_object(Configuration.new) do |anc, hash|
        next if anc == self || !anc.respond_to?(:config)
        hash.merge!(anc.config)
      end
    end

    # Load every config file from all config directories that match the given
    # config patterns.
    def self.load_configs
      return false if config.config_folders.empty? || config.config_patterns.empty?
      config.config_folders.each do |dir|
        logger.info("Searching for configuration files in #{dir}.")
        BBLib.scan_files(dir, *config.config_patterns) do |file|
          load_config(file)
        end
      end
      true
    end

    # Load a given config file at a path on disk. Can be JSON or YML
    def self.load_config(file)
      name = file.file_name(false).to_sym
      custom_loader = "load_#{name}_config"
      if respond_to?(custom_loader)
        send(custom_loader, file)
      else
        config(name => Harmoni.build(file, sync: config.sync_configs))
        logger.info("Successfully loaded config file #{name} (#{file})")
      end
    rescue StandardError => e
      logger.error("Failed to load config file at #{file}: #{e}")
      raise e
    end

    # Load the application config for the current environment.
    def self.load_application_config(file)
      logger.debug("Loading application configuration from #{file}")
      config = Harmoni.build(file)
      config = config.except(:environment).deep_merge(config[environment] || {}).to_hash_struct
      (config.settings || {}).each { |k, v| set(k, v) }
      (config.config || {}).each { |k, v| config(k => v) }
      true
    end

    # Loader to build databases from a yml config file
    def self.load_database_config(file)
      logger.info("Loading database(s) from config at #{file}")
      config = Harmoni.build(file)
      databases = [config[environment], config[:default]].flatten(1).compact
      databases.each do |db|
        BlockStack::Database.setup(db[:name], db[:adapter], *[db[:configuration]].flatten(1))
      end
      true
    end
  end
end

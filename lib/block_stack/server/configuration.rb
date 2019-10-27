module BlockStack
  class Server < Sinatra::Base
    # This object holds all of the configuration for a server.
    class Configuration < BBLib::HashStruct
      include BBLib::Effortless

      # Basic Configuration
      # -------------------
      # The base class to automatically load controllers from
      attr_of Class, :controller_base, default: BlockStack::Controller, allow_nil: true
      # When set to true the run! method will analyze the arguments in the ARGV constant
      attr_bool :parse_argv, default: true
      # The base URL for this server. This is primarily for DNS or load balanced names. This
      # is used for absolute URLs that refer back to the server externally.
      attr_str :app_address, default: "http://localhost:4567"

      # Config File Configuration
      # -------------------------
      # When set to a valid directory, any yaml or json configuration files will be automatically loaded
      # into this config structure using the Harmony gem.
      attr_ary_of String, :config_folders, default: []
      # When set to true, configs will be read in with sync set to true in Harmony (auto refreshed from and to disk on change)
      attr_bool :sync_configs, default: false
      # The file extensions that will be automatically read in as config files.
      attr_ary_of [String, Regexp], :config_patterns, default: %w{application.yml database.yml authentication.yml}

      # API Configuration
      # -----------------
      # When set to true if a route returns an object that response to the serialize method it will
      # be serialized before being passed to the assigned formatter.
      attr_bool :auto_serialize, default: true

      # Output Configuration
      # --------------------
      # When set to true HTTP requests will be logged for every route
      attr_bool :log_requests, default: true

      # TODO Implement the below
      # The setters below are not yet used in the BlockStack::Server
      # ------------------------------------------------------------
      # Load all models, controllers and app files on each request. Useful for testing only.
      # attr_bool :hot_load, default: false


      init_type :loose

      def set(args)
        args.each do |key, value|
          if respond_to?("#{key}=")
            send("#{key}=", value)
          else
            hpath_set(key => value)
          end
        end
      end

      alias _serialize serialize

      def serialize(hide_defaults = false)
        _serialize(hide_defaults).merge(self)
      end

      alias_method :to_h, :serialize

      protected

      def simple_init(*args)
        BBLib.named_args(*args).each do |k, v|
          next if self.respond_to?(k)
          self.send("#{k}=", v)
        end
      end
    end
  end
end

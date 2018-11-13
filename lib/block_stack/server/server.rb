require_relative 'helpers'
require_relative 'template/template'

module BlockStack
  class Server < Sinatra::Base
    extend BBLib::Attrs
    extend BBLib::FamilyTree
    extend BBLib::Bridge

    helpers Helpers::Server

    attr_ary_of String, :api_routes, singleton: true, default: [], add_rem: true
    attr_ary_of Formatter, :formatters, default_proc: :default_formatters, singleton: true
    attr_sym :default_format, default: :json, allow_nil: true, singleton: true
    attr_of BBLib::HashStruct, :configuration, default_proc: :inherited_config, singleton: true
    attr_of BBLib::OptsParser, :opts_parser, default_proc: proc { BlockStack::DEFAULT_OPTS_PARSER }, singleton: true

    bridge_method :route_map, :route_names, :api_routes, :formatters, :default_formatters, :default_format
    bridge_method :logger, :debug, :info, :warn, :error, :fatal, :timer, :app_name, :config

    # Set or retrieve configuration variables or the entire config object.
    def self.config(args = nil)
      case args
      when Hash
        configuration.hpath_set(args)
      when String, Symbol
        configuration.to_h.hpath(args).first
      when nil
        configuration
      else
      end
    end

    # Loads the configuration of an ancestors this class inherits from.
    def self.inherited_config
      ancestors.reverse.each_with_object(BBLib::HashStruct.new) do |anc, hash|
        next if anc == self || !anc.respond_to?(:config)
        hash.merge!(anc.config)
      end
    end

    # Setup default settings
    config(
      controller_base: nil,  # Set this to a class that inherits from BlockStack::Controller
      log_requests: true,
      auto_serialize: true, # If true all objects that respond to serialize will be serialized before being passed to the formatter (api routes only)
      parse_argv: false, # If set to true, whenever run! is called cmdline args will be parsed and applied based on the :opts_parser
      config_folder: nil, # Should be set to a directory contain json or yaml configuration files. nil turns off on disk config loading.
      sync_configs: false, # When true config files will be auto refreshed from disk.
      config_extensions: %w{yml yaml json} # The file extensions that will be used when loading configs from the config directory.
    )

    class << self
      # Overwrite the origin http verb methods from Sinatra to extend functionality
      BlockStack::VERBS.each do |verb|
        define_method(verb) do |route, opts = {}, &block|
          route = build_route(route, verb, api: opts[:api])
          add_api_routes("#{verb.to_s.upcase} #{route}") if opts.delete(:api)
          super(route, opts, &block)
        end

        # Add API specific methods foreach HTTP method.
        define_method("#{verb}_api") do |route, opts = {}, &block|
          send(verb, route, opts.merge(api: true), &block)
        end
      end

      # Add logging methods for conveniece.
      [:debug, :info, :warn, :error, :fatal].each do |sev|
        define_method(sev) do |*args|
          args.each { |a| logger.send(sev, a) }
        end
      end
    end

    # Attach the default BlockStack logger.
    def self.logger
      @logger ||= BlockStack.logger
    end

    # Override with a custom logger.
    def self.logger=(logr)
      @logger = logr
    end

    # This method is used by controllers to find the root server. Controllers
    # load behavior and configuration from the base server as well as using it
    # for shared functionality like authentication.
    def self.base_server
      self
    end

    bridge_method :base_server

    # Returns this servers prefix
    def self.prefix
      @prefix
    end

    # Can be used to add a prefix to every route on this server.
    def self.prefix=(pre)
      pre = pre.to_s.uncapsulate('/') if pre
      return @prefix if @prefix == pre
      change_prefix(@prefix, pre.uncapsulate('/'))
      @prefix = pre
    end

    # Returns this server's api prefix
    def self.api_prefix
      @api_prefix
    end

    # Sets a custom prefix for all API routes, separate from the prefix.
    # This prefix comes before the main prefix.
    def self.api_prefix=(pre)
      pre = pre.to_s.uncapsulate('/') if pre
      return @api_prefix if @api_prefix == pre
      change_prefix(@prefix, pre)
      @api_prefix = pre
    end

    # Builds a route using various options and configurations
    def self.build_route(path, verb, opts = {})
      path = [self.prefix, path].flatten
      path.push(opts[:suffix]) if opts[:suffix]
      path.unshift(opts[:prefix]) if opts[:prefix]
      path.unshift("v#{opts[:version]}") if opts[:version]
      path.unshift(api_prefix) if opts[:api] and api_prefix
      path = "/#{path.compact.join('/')}/?".pathify.gsub(/\/+/, '/')
      (path.end_with?('/') ? "#{path}?" : path) + (verb == :get && opts[:api] ? '(.:format)?' : '')
    end

    # Returns a hash of all routes current configured on this server.
    def self.route_names(verb)
      return [] unless routes[verb.to_s.upcase]
      routes[verb.to_s.upcase].map { |route| route[0].to_s }
    end

    # Get a list of all registered routes grouped by http verb
    def self.route_map(include_controllers = true)
      routes = BlockStack::VERBS.hmap { |verb| [verb, route_names(verb)] }
      controllers.each { |c| routes = routes.deep_merge(c.route_map) }
      routes
    end

    # Convenient way to delete a route from this server
    def self.remove_route(verb, route)
      index = nil
      verb = verb.to_s.upcase
      routes[verb].each_with_index do |rt, i|
        index = i if rt[0].to_s == route.to_s
      end
      return false unless index
      routes[verb].delete_at(index)
    end

    # Attaches a route template from the BlockStack template store.
    def self.attach_template(title, group = nil, **opts)
      template = BlockStack.template(title, group)
      raise ArgumentError, "No BlockStack template found with a title of #{title} and a group of #{group || :nil}." unless template
      template.add_to(self, opts)
      true
    end

    # Attaches an entire group of templates from the BlockStack template store.
    def self.attach_template_group(group, *except)
      BlockStack.template_group(group).each do |template|
        next if except.include?(template.title)
        template.add_to(self)
      end
      true
    end

    # Provides a list of controllers that this server should use
    def self.controllers
      load_controller_base
    end

    # Add a controller to this server
    def self.add_controller(controller)
      raise ArgumentError, "Invalid controller class: #{controller}. Must be inherited from BlockStack::Controller." unless controller <= BlockStack::Controller
      (@controllers ||= [])
      @controllers << controller
    end

    # Remove a controller from this server (does not affect controllers loaded via controller_base)
    def self.remove_controller(controller)
      (@controllers ||= []).delete(controller)
    end

    # Builds a set of default formatters for API routes
    def self.default_formatters
      [
        BlockStack::Formatters::HTML.new,
        BlockStack::Formatters::JSON.new,
        BlockStack::Formatters::YAML.new,
        BlockStack::Formatters::XML.new,
        BlockStack::Formatters::Text.new,
        BlockStack::Formatters::CSV.new,
        BlockStack::Formatters::TSV.new
      ]
    end

    # Convenience method that will load JSON from the request body.
    def json_request
      request.body.rewind
      JSON.parse(request.body.read).keys_to_sym
    rescue => _e
      {}
    end

    before do
      env['rack.logger'] = logger
      if config.log_requests
        timer.start(request.object_id)
      end
    end

    # Check each response to see if it is an API route.
    # If it is an API route we will attempt to format the response.
    after do
      if api_routes.include?(request.env['sinatra.route'].to_s) && !response.body.is_a?(Rack::File::Iterator)
        formatter = pick_formatter(request, params)
        if formatter
          body = response.body
          if config.auto_serialize
            if body.respond_to?(:serialize)
              body = body.serialize
            elsif body.is_a?(Array)
              body = body.map { |obj| obj.respond_to?(:serialize) ? obj.serialize : obj }
            end
          end
          content_type(formatter.content_type)
          response.body = formatter.process(body, params)
        else
          halt 406, "No formatter found"
        end
      end

      if !env['logged'] && config.log_requests && message = log_request
        env['logged'] = true
        info(message)
      end
    end

    # Returns a basic task timer that can be used to time requests and other
    # tasks. By default it is only used to calculate request times.
    def self.timer
      @timer ||= BBLib::TaskTimer.new
    end

    # Writes a log message for the current request.
    # TODO Make this more customizable
    def log_request
      "#{request.ip} - #{session[:login] ? session[:login].name : '-'} [#{Time.now.strftime('%d/%m/%Y:%H:%M:%S %z')}] \"#{request.request_method} #{request.path} HTTP\" #{response.status} #{response.content_length} #{timer.stop(request.object_id).round(3)}"
    end

    # Override default Sinatra run. Registers controllers before running.
    def self.run!(*args)
      parse_argv if config.parse_argv?
      logger.info("Starting up your BlockStack server")
      register_controllers
      super
    end

    # Parses arguments from argv using this classes opts_parser.
    def self.parse_argv
      @parsed_args = opts_parser.parse
      @parsed_args.only(:bind, :port, :environment).each { |k, v| set(k => v) }
      config(@parsed_args.except(:help, :log_level))
    end

    def self.load_configs
      return false unless config.config_folder
      logger.info("Loading config files from #{config.config_folder} with extensions #{config.config_extensions.join_terms(:or)}")
      if Dir.exist?(config.config_folder.to_s)
        extensions = config.config_extensions.map { |ext| "*.#{ext}" }
        BBLib.scan_files(config.config_folder.to_s, *extensions) do |file|
          begin
            config(file.file_name(false).to_sym => Harmoni.build(file, sync: config.sync_configs))
            logger.info("Loaded config file #{file.file_name(false)}.")
          rescue => e
            logger.error("Failed to load config file #{file}: #{e}\n\t#{e.backtrace.join("\n\t")}")
          end
        end
      else
        logger.warn("Config folder does not exist at #{config.config_folder}. No configs will be loaded.")
      end
    end

    protected

    def pick_formatter(request, params)
      unless params[:format]
        file_type = File.extname(request.path_info).sub('.', '').to_s.downcase.to_sym
        params[:format] = file_type
      end
      formatters.find { |f| f.format_match?(params[:format]) } ||
      default_format && formatters.find { |f| f.format_match?(default_format) } ||
      formatters.find { |f| f.mime_type_match?(request.accept) }
    end

    # Loads all controllers into this server via rack
    def self.register_controllers
      controllers.each do |controller|
        debug("Registering new controller: #{controller}")
        controller.base_server = self
        use controller
      end
    end

    # If a controller base is set, controllers are loaded from it.
    # All descendants of each controller_base will be discovered.
    def self.load_controller_base
      [config.controller_base].flatten.compact.flat_map(&:descendants).uniq.reject { |c| c == self }
    end

    # This method is invoked any time the prefix of the server is changed.
    # All existing routes will have their route prefix updated.
    def self.change_prefix(old, new)
      if old
        info("Changing prefix from '#{old}' to '#{new}'...")
      else
        debug("Adding route prefix to existing routes: #{new}")
      end
      routes.each do |verb, rts|
        rts.each do |route|
          current = route[0].to_s
          full = "#{verb} #{current}"
          if api_routes.include?(full)
            verb, path = api_routes.delete(full).split(' ', 2)
            path = path.sub("/#{api_prefix}", '') if api_prefix
            path = path.sub(/^\/#{Regexp.escape(old)}/i, '') if old
            replace = "#{api_prefix ? "/#{api_prefix}" : nil}/#{new}"
            logger.debug("Changing API route from '#{current}' to #{replace}#{path}")
            add_api_routes("#{verb} #{replace}#{path}")
            current = path
          else
            replace = "/#{new}"
          end
          current = current.sub(/^\/#{Regexp.escape(old)}/i, '') if old
          route[0] = Mustermann.new("#{replace}#{current}", route[0].options)
        end
      end
    end
  end
end

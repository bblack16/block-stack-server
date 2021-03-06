module BlockStack

  LOG_LEVELS = %w{debug info warn error fatal}.freeze

  DEFAULT_OPTS_PARSER = BBLib::OptsParser.new do |parser|
    parser.usage = 'Usage: block-stack run [options...]'
    parser.string('-b', '--bind', desc: 'The address to bind to.')
    parser.integer('-p', '--port', desc: 'The port to listen on.')
    parser.toggle('--precompile', desc: 'When passed assets will be precompiled before the server starts.')
    parser.symbol('-e', '--environment', desc: 'The environment to load. Only matters if environments have been configured.')
    parser.toggle('-h', '--help', desc: 'Display help for your BlockStack server.') do
      puts parser.help
      exit
    end
    parser.element_of('-l', '--log-level', desc: "Set the log level. Options are: #{LOG_LEVELS.join_terms}", options: LOG_LEVELS) do |sev|
      BlockStack.logger.level = sev.downcase.to_sym
    end
  end

end

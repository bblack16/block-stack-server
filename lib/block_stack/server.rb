require 'block_stack/util' unless defined?(BlockStack::Util)
require 'block_stack/model' unless defined?(BlockStack::Model)
require 'block_stack/query' unless defined?(BlockStack::Query)

require 'bblib/cli' unless defined?(BBLib::OptsParser)
require 'json'
require 'yaml'
require 'sinatra'
require 'task_vault' unless defined?(TaskVault::VERSION)
require 'harmoni' unless defined?(Harmoni::VERSION)

# require_relative 'server/version'
require_relative 'server/cli/opts_parser'
require_relative 'server/server'
require_relative 'server/controller'
require_relative 'server/configuration'
require_relative 'server/async'

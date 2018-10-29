require 'block_stack/util' unless defined?(BlockStack::Util)
require 'block_stack/model' unless defined?(BlockStack::Model)
require 'block_stack/query' unless defined?(BlockStack::Query)

require 'json'
require 'yaml'
require 'sinatra'
require 'task_vault' unless defined?(TaskVault::VERSION)

# require_relative 'server/version'
require_relative 'server/async'
require_relative 'server/server'
require_relative 'server/controller'

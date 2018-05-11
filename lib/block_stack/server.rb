require 'block_stack/util' unless defined?(BlockStack::Util)

require 'json'
require 'yaml'
require 'sinatra'

require_relative 'server/version'
require_relative 'server/server'
require_relative 'server/controller'

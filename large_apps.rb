#!/usr/bin/env ruby
LEVELS = (ARGV.first || 5).to_i
ROUTES_PER_LEVEL = (ARGV.last || 10).to_i
BASE_ROUTE = 'a'.freeze

roda_routes = lambda do |f, level|
  base = BASE_ROUTE.dup
  spaces = "  " * (LEVELS - level + 1)
  meth = (level == 1 ? 'get' : 'on')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}r.#{meth} '#{base}' do"
    if level == 1
      f.puts "#{spaces}  r.full_path_info"
    else
      roda_routes.call(f, level-1)
    end
    base.succ!
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/roda_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "Roda.route do |r|"
  roda_routes.call(f, LEVELS)
  f.puts "end"
  f.puts "App = Roda.app"
end

sinatra_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}' do"
      f.puts "    request.path_info"
      f.puts "  end"
    else
      sinatra_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/sinatra_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'sinatra/base'"
  f.puts "class App < Sinatra::Base"
  sinatra_routes.call(f, LEVELS, '/')
  f.puts "end"
end

rails_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  controller = prefix.gsub('/', '_')
  controller = 'main' if controller.empty?
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{'/' unless prefix.empty?}#{base}' => '#{controller}##{base}'"
    else
      rails_routes.call(f, level-1, "#{prefix}#{'/' unless prefix.empty?}#{base}")
    end
    base.succ!
  end
end

rails_controllers = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  if level == 1
    f.puts "class #{prefix.empty? ? 'Main' : prefix}Controller < ApplicationController"
    ROUTES_PER_LEVEL.times do
      f.puts "  def #{base}"
      f.puts "    render :text=>request.path_info"
      f.puts "  end"
      base.succ!
    end
    f.puts "end"
  else
    ROUTES_PER_LEVEL.times do
      rails_controllers.call(f, level-1, "#{prefix}#{base.upcase}")
      base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/rails_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts <<END
require 'action_controller/railtie'
class App < Rails::Application
  config.secret_token = '1234567890'*5
  config.secret_key_base = 'foo'
  config.eager_load = true
  config.active_support.deprecation = :stderr
  config.middleware.delete(ActionDispatch::ShowExceptions)
  config.middleware.delete("Rack::Lock")
  config.logger = Logger.new('/dev/null')
  config.logger.level = 4
end
class ApplicationController < ActionController::Base
end
END
  rails_controllers.call(f, LEVELS, '')
  f.puts "App.initialize!"
  f.puts "App.routes.clear!"
  f.puts "App.routes.draw do"
  rails_routes.call(f, LEVELS, '')
  f.puts "end"
end


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
      f.puts "    render :text=>'#{RESULT.call((prefix + base).downcase.split(//).join('/'))}'"
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

File.open("#{File.dirname(__FILE__)}/../apps/rails-minimal-middleware_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts <<END
# frozen-string-literal: true
require 'action_controller/railtie'
class App < Rails::Application
  config.secret_key_base = 'foo'
  config.cache_classes = true
  config.eager_load = true
  config.public_file_server.enabled = false
  config.active_support.deprecation = :stderr

  config.middleware.delete(ActionDispatch::ShowExceptions)
  config.middleware.delete("Rack::Lock")
  config.middleware.delete(ActionDispatch::Static)
  config.middleware.delete(ActiveSupport::Cache::Strategy::LocalCache::Middleware)
  config.middleware.delete(ActionDispatch::RequestId)
  config.middleware.delete(Rails::Rack::Logger)
  config.middleware.delete(ActionDispatch::DebugExceptions)
  config.middleware.delete(ActionDispatch::RemoteIp)
  config.middleware.delete(ActionDispatch::Reloader)
  config.middleware.delete('ActiveRecord::Migration::CheckPending')
  config.middleware.delete('ActiveRecord::ConnectionAdapters::ConnectionManagement')
  config.middleware.delete('ActiveRecord::QueryCache')
  config.middleware.delete(ActionDispatch::ParamsParser)
  config.middleware.delete(Rack::Head)
  config.middleware.delete(Rack::ConditionalGet)
  config.middleware.delete(Rack::ETag)

  config.middleware.use(Rack::ContentLength)
  config.logger = Logger.new('/dev/null')
  config.logger.level = 4
  config.log_level = :error 
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



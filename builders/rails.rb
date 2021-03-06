rails_routes = lambda do |f, level, prefix, lvars|
  base = BASE_ROUTE.dup
  controller = prefix.gsub('/', '').gsub(/:\w/, '')
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}/:#{lvars.last}' => 'main##{controller}#{base}'"
    else
      rails_routes.call(f, level-1, "#{prefix}#{base}/:#{lvars.last}/", lvars + [lvars.last.succ])
    end
    base.succ!
  end
end

rails_controllers = lambda do |f, level, prefix, lvars|
  base = BASE_ROUTE.dup
  if level == 1
    ROUTES_PER_LEVEL.times do
      f.puts "  def #{(prefix + base).gsub('/', '')}"
      f.puts "    render :html=>\"#{RESULT.call(prefix + base)}#{lvars.map{|lvar| "-\#{params[:#{lvar}]}"}.join}\""
      f.puts "  end"
      base.succ!
    end
  else
    ROUTES_PER_LEVEL.times do
      rails_controllers.call(f, level-1, "#{prefix}#{base}/", lvars + [lvars.last.succ])
      base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/rails_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts <<END
# frozen-string-literal: true
require 'action_controller/railtie'
class App < Rails::Application
  config.secret_token = '1234567890'*5
  config.secret_key_base = 'foo'
  config.eager_load = true
  config.active_support.deprecation = :stderr
  config.middleware.delete(ActionDispatch::ShowExceptions)
  config.middleware.delete(Rack::Lock)
  config.middleware.use(Rack::ContentLength)
  config.logger = Logger.new('/dev/null')
  config.logger.level = 4
  config.log_level = :error 
end
class ApplicationController < ActionController::Base
  def route_not_found
    head 404
  end
end
class MainController < ApplicationController
END
  rails_controllers.call(f, LEVELS, '', ['a'])
  f.puts "end"
  f.puts "App.initialize!"
  f.puts "App.routes.clear!"
  f.puts "App.routes.draw do"
  rails_routes.call(f, LEVELS, '/', ['a'])
  f.puts "  match '*unmatched', to: 'application#route_not_found', via: :all"
  f.puts "end"
end



#!/usr/bin/env ruby
LEVELS = (ARGV.first || 5).to_i
ROUTES_PER_LEVEL = (ARGV.last || 10).to_i
BASE_ROUTE = 'a'.freeze

integer = proc{|path| "/#{path}".split(//).map{|c| c.ord.to_s}.join}

roda_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  spaces = "  " * (LEVELS - level + 1)
  meth = (level == 1 ? 'is' : 'on')
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}r.#{meth} '#{base}' do"
    if level == 1
      f.puts "#{spaces}  '#{integer.call(prefixes.empty? ? base : "#{prefix}/#{base}")}'"
    else
      roda_routes.call(f, level-1, prefixes + [base.dup])
    end
    base.succ!
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/roda_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "Roda.route do |r|"
  f.puts "r.get do"
  roda_routes.call(f, LEVELS, [])
  f.puts "end"
  f.puts "end"
  f.puts "App = Roda.app"
end

roda_multi_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  meth = (level == 1 ? 'is' : 'on')
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    f.puts "Roda.route('#{base}'#{", '#{prefix}'" unless prefixes.empty?}) do |r|"
    if level == 1
      f.puts "  '#{integer.call(prefixes.empty? ? base : "#{prefix}/#{base}")}'"
    else
      f.puts "  r.multi_route('#{"#{prefix}/" unless prefixes.empty?}#{base}')"
    end
    f.puts "end"
    roda_multi_routes.call(f, level-1, prefixes + [base.dup]) unless level == 1
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/roda-multi-route_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "Roda.plugin :multi_route"
  f.puts "Roda.route do |r|"
  f.puts "  r.multi_route"
  f.puts "end"
  roda_multi_routes.call(f, LEVELS, [])
  f.puts "App = Roda.app"
end

rodarun_apps = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup

  prefix = prefixes.join('/')
  f.puts "class #{prefixes.empty? ? 'Main' : "#{prefixes.join.upcase}"}_App < ::Roda"
  f.puts "  route do |r|"
  meth = ( level == 1 ? 'get' : 'on' )
  ROUTES_PER_LEVEL.times do
    subtask = ( level == 1 ? "'#{integer.call((prefixes + [base]).join('/'))}'" : "r.run #{prefixes.join.upcase}#{base.upcase}_App" )
    f.puts "    r.#{meth} '#{base}' do"
    f.puts "      #{subtask}"
    f.puts "    end"
    base.succ!
  end
  f.puts "  end"
  f.puts "end"

  if level > 1 then
    next_base = BASE_ROUTE.dup
    ROUTES_PER_LEVEL.times do
      rodarun_apps.call(f, level-1, prefixes + [next_base])
      next_base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/roda-run_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  rodarun_apps.call(f, LEVELS, [])
  f.puts "App = Main_App"
end

cuba_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  spaces = "  " * (LEVELS - level + 1)
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    arg = (level == 1 ? "/#{base}\\z/" : "'#{base}'")
    f.puts "#{spaces}on #{arg} do"
    if level == 1
      f.puts "#{spaces}  res.write('#{integer.call(prefixes.empty? ? base : "#{prefix}/#{base}")}')"
    else
      cuba_routes.call(f, level-1, prefixes + [base.dup])
    end
    base.succ!
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/cuba_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'cuba'"
  f.puts "Cuba.define do"
  f.puts "on get do"
  cuba_routes.call(f, LEVELS, [])
  f.puts "end"
  f.puts "end"
  f.puts "App = Cuba"
end

sinatra_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}' do"
      f.puts "    '#{integer.call(prefix[1..-1] + base)}'"
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
      f.puts "    render :text=>'#{integer.call((prefix + base).downcase.split(//).join('/'))}'"
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


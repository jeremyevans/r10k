hanami_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  controller = prefix.gsub('/', '_')
  controller = 'main' if controller.empty?
  spaces = "  " * (LEVELS - level + 1)
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "#{spaces}  get '/#{base}' do\n#{spaces}'#{RESULT.call((prefix + base).downcase.split(//).join('/'))}'\n#{spaces}end"
    else
      f.puts "#{spaces}scope '#{base}' do"
      hanami_routes.call(f, level-1, "#{prefix}#{'/' unless prefix.empty?}#{base}")
      f.puts "#{spaces}end"
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/hanami-api_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen_string_literal: true"
  f.puts "require 'hanami/api'"
  f.puts "class API < Hanami::API"
  hanami_routes.call(f, LEVELS, '')
  f.puts "end"
  f.puts "App = API.new"
end

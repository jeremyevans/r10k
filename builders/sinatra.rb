sinatra_routes = lambda do |f, level, prefix, calc_path, lvars|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}/:#{lvars.last}' do |#{lvars.join(', ')}|"
      f.puts "    \"#{RESULT.call(calc_path[1..-1] + base)}#{lvars.map{|lvar| "-\#{#{lvar}}"}.join}\""
      f.puts "  end"
    else
      sinatra_routes.call(f, level-1, "#{prefix}#{base}/:#{lvars.last}/", "#{calc_path}#{base}/", lvars + [lvars.last.succ])
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/sinatra_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'sinatra/base'"
  f.puts "class App < Sinatra::Base"
  sinatra_routes.call(f, LEVELS, '/', "/", ['a'])
  f.puts "end"
end

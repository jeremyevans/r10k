nyny_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}' do"
      f.puts "    '#{RESULT.call(prefix[1..-1] + base)}'"
      f.puts "  end"
    else
      nyny_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/nyny_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'nyny'"
  f.puts "class AppClass < NYNY::App"
  nyny_routes.call(f, LEVELS, '/')
  f.puts "end"
  f.puts "App = AppClass.new"
end


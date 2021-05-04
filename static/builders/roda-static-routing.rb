roda_static_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  static_get '#{prefix}#{base}' do |r|"
      f.puts "    '#{RESULT.call(prefix[1..-1] + base)}'"
      f.puts "  end"
    else
      roda_static_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-static-routing_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "class Roda"
  f.puts "  plugin :static_routing"
  f.puts "  plugin :direct_call"
  roda_static_routes.call(f, LEVELS, '/')
  f.puts "  route do |r|"
  f.puts "  end"
  f.puts "end"
  f.puts "App = Roda.freeze.app"
end

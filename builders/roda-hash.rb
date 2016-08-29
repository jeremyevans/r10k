roda_hash_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  routes['#{prefix}#{base}'] = lambda do |r|"
      f.puts "    '#{RESULT.call(prefix[1..-1] + base)}'"
      f.puts "  end"
    else
      roda_hash_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-hash_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "class App < Roda"
  f.puts "routes = {}"
  roda_hash_routes.call(f, LEVELS, '/')
  f.puts "route{|r| instance_exec(r, &routes[r.remaining_path])}"
  f.puts "end"
end

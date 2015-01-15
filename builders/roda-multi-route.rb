roda_multi_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  meth = (level == 1 ? 'is' : 'on')
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    f.puts "Roda.route('#{base}'#{", '#{prefix}'" unless prefixes.empty?}) do |r|"
    if level == 1
      f.puts "  '#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}'"
    else
      f.puts "  r.multi_route('#{"#{prefix}/" unless prefixes.empty?}#{base}')"
    end
    f.puts "end"
    roda_multi_routes.call(f, level-1, prefixes + [base.dup]) unless level == 1
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-multi-route_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "Roda.plugin :multi_route"
  f.puts "Roda.route do |r|"
  f.puts "  r.multi_route"
  f.puts "end"
  roda_multi_routes.call(f, LEVELS, [])
  f.puts "App = Roda.app"
end

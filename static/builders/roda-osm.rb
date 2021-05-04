roda_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  spaces = "  " * (LEVELS - level + 1)
  meth = (level == 1 ? 'is_exactly' : 'on_branch')
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}r.#{meth} '#{base}' do"
    if level == 1
      f.puts "#{spaces}  '#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}'"
    else
      roda_routes.call(f, level-1, prefixes + [base.dup])
    end
    base.succ!
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-osm_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "Roda.plugin :optimized_string_matchers"
  f.puts "Roda.plugin :direct_call"
  f.puts "Roda.route do |r|"
  f.puts "r.get do"
  roda_routes.call(f, LEVELS, [])
  f.puts "end"
  f.puts "end"
  f.puts "App = Roda.freeze.app"
end

roda_routes = lambda do |f, level, prefixes, lvars|
  base = BASE_ROUTE.dup
  spaces = "  " * (2*(LEVELS - level + 1) - 1)
  prefix = prefixes.join('/')
  meth = (level == 1 ? 'get' : 'on')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}r.on '#{base}' do"
    f.puts "#{spaces}  r.#{meth} String do |#{lvars.last}|"
    if level == 1
      f.puts "#{spaces}    \"#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}#{lvars.map{|lvar| "-\#{#{lvar}}"}.join}\""
    else
      roda_routes.call(f, level-1, prefixes + [base.dup], lvars + [lvars.last.succ])
    end
    base.succ!
    f.puts "#{spaces}  end"
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "Roda.route do |r|"
  f.puts "r.get do"
  roda_routes.call(f, LEVELS, [], ['a'])
  f.puts "end"
  f.puts "end"
  f.puts "App = Roda.freeze.app"
end

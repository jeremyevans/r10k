cuba_routes = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup
  spaces = "  " * (LEVELS - level + 1)
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    arg = (level == 1 ? "/#{base}\\z/" : "'#{base}'")
    f.puts "#{spaces}on #{arg} do"
    if level == 1
      f.puts "#{spaces}  res.write('#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}')"
    else
      cuba_routes.call(f, level-1, prefixes + [base.dup])
    end
    base.succ!
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/cuba_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'cuba'"
  f.puts "Cuba.define do"
  f.puts "on get do"
  cuba_routes.call(f, LEVELS, [])
  f.puts "end"
  f.puts "end"
  f.puts "App = Cuba"
end

syro_routes = lambda do |f, level, prefixes, lvars|
  base = BASE_ROUTE.dup
  spaces = "  " * (2*(LEVELS - level + 1) - 1)
  prefix = prefixes.join('/')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}on '#{base}' do"
    f.puts "#{spaces}  on :#{lvars.last} do"
    if level == 1
      f.puts "#{spaces}    get do"
      f.puts "#{spaces}      res.html(\"#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}#{lvars.map{|lvar| "-\#{inbox[:#{lvar}]}"}.join}\")"
      f.puts "#{spaces}    end"
    else
      syro_routes.call(f, level-1, prefixes + [base.dup], lvars + [lvars.last.succ])
    end
    base.succ!
    f.puts "#{spaces}  end"
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/syro_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'syro'"
  f.puts "app = Syro.new do"
  syro_routes.call(f, LEVELS, [], ['a'])
  f.puts "end"
  f.puts "App = app"
end


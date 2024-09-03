roda_routes = lambda do |f, level, prefixes, lvars|
  base = BASE_ROUTE.dup
  spaces = "  " * (2*(LEVELS - level + 1) - 1)
  prefix = prefixes.join('/')
  meth = (level == 1 ? 'is_segment' : 'on_segment')
  ROUTES_PER_LEVEL.times do
    f.puts "#{spaces}r.on_branch '#{base}' do"
    f.puts "#{spaces}  r.#{meth} do |#{lvars.last}|"
    if level == 1
      f.puts "#{spaces}    r.get do"
      f.puts "#{spaces}      \"#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}#{lvars.map{|lvar| "-\#{#{lvar}}"}.join}\""
      f.puts "#{spaces}    end"
    else
      roda_routes.call(f, level-1, prefixes + [base.dup], lvars + [lvars.last.succ])
    end
    base.succ!
    f.puts "#{spaces}  end"
    f.puts "#{spaces}end"
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-osm_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "Roda.plugin :optimized_string_matchers"
  f.puts "Roda.plugin :optimized_segment_matchers"
  f.puts "Roda.plugin :direct_call"
  f.puts "Roda.plugin :plain_hash_response_headers rescue nil"
  f.puts "Roda.route do |r|"
  f.puts "r.get do"
  roda_routes.call(f, LEVELS, [], ['a'])
  f.puts "end"
  f.puts "end"
  f.puts "App = Roda.freeze.app"
end

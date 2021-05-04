roda_hash_branches = lambda do |f, level, prefixes, lvars|
  base = BASE_ROUTE.dup
  meth = (level == 1 ? 'hash_path' : 'hash_branch')
  prefix = prefixes.join('/')
  f.puts "Roda.hash_routes('#{"/#{prefix}" unless prefixes.empty?}') do"
  nested = []
  ROUTES_PER_LEVEL.times do
    f.puts "  on('#{base}') do |r|"
    case level
    when 1
      f.puts "    r.get String do |#{lvars.last}|"
      f.puts "      \"#{RESULT.call(prefixes.empty? ? base : "#{prefix}/#{base}")}#{lvars.map{|lvar| "-\#{#{'@' unless lvar == lvars.last}#{lvar}}"}.join}\""
    else
      f.puts "    r.on String do |#{lvars.last}|"
      f.puts "      @#{lvars.last} = #{lvars.last}"
      f.puts "      r.hash_branches('#{"/#{prefix}" unless prefixes.empty?}/#{base}')"
    end
    f.puts "    end"
    f.puts "  end"
    nested << [f, level-1, prefixes + [base.dup], lvars + [lvars.last.succ]] unless level == 1
    base.succ!
  end
  f.puts "end"
  nested.each do |n|
    roda_hash_branches.call(*n)
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-hash-routes_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "Roda.plugin :hash_routes"
  f.puts "Roda.plugin :direct_call"
  f.puts "Roda.route do |r|"
  f.puts "  r.hash_branches('')"
  f.puts "end"
  roda_hash_branches.call(f, LEVELS, [], ['a'])
  f.puts "App = Roda.freeze.app"
end

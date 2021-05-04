rodarun_apps = lambda do |f, level, prefixes|
  base = BASE_ROUTE.dup

  prefix = prefixes.join('/')
  f.puts "class #{prefixes.empty? ? 'Main' : "#{prefixes.join.upcase}"}_App < ::Roda"
  f.puts "  route do |r|"
  meth = ( level == 1 ? 'get' : 'on' )
  ROUTES_PER_LEVEL.times do
    subtask = ( level == 1 ? "'#{RESULT.call((prefixes + [base]).join('/'))}'" : "r.run #{prefixes.join.upcase}#{base.upcase}_App" )
    f.puts "    r.#{meth} '#{base}' do"
    f.puts "      #{subtask}"
    f.puts "    end"
    base.succ!
  end
  f.puts "  end"
  f.puts "end"

  if level > 1 then
    next_base = BASE_ROUTE.dup
    ROUTES_PER_LEVEL.times do
      rodarun_apps.call(f, level-1, prefixes + [next_base])
      next_base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-run_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'roda'"
  f.puts "Roda.plugin :direct_call"
  rodarun_apps.call(f, LEVELS, [])
  f.puts "App = Main_App.freeze.app"
end

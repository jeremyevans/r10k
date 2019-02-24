watts_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  resource('#{prefix}#{base}', Class.new(Watts::Resource) do"
      f.puts "    get { '#{RESULT.call(prefix[1..-1] + base)}' }"
      f.puts "  end)"
    else
      watts_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/watts_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'watts'"
  f.puts "class AppClass < Watts::App"
  watts_routes.call(f, LEVELS, '/')
  f.puts "  def call(env, req_path = nil)"
  f.puts "    res = super"
  f.puts "    res[1]['Content-Type'] = 'text/html'"
  f.puts "    res"
  f.puts "  end"
  f.puts "end"
  f.puts "App = AppClass.new"
end

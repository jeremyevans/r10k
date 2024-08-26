camping_routes = lambda do |f, level, prefix, calc_path, lvars|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  class #{(prefix+base).scan(/\/\w+/).flatten.join.gsub('/', '').upcase}_ < R '#{prefix}#{base}/([^/]+)'"
      f.puts "    def get(#{lvars.join(', ')})"
      f.puts "      \"#{RESULT.call(calc_path[1..-1] + base)}#{lvars.map{|lvar| "-\#{#{lvar}}"}.join}\""
      f.puts "    end"
      f.puts "  end"
    else
      camping_routes.call(f, level-1, "#{prefix}#{base}/([^/]+)/", "#{calc_path}#{base}/", lvars + [lvars.last.succ])
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/camping_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'camping'"
  f.puts "Camping.goes :App"
  f.puts "module App::Controllers"
  camping_routes.call(f, LEVELS, '/', "/", ['a'])
  f.puts "  M(nil)"
  f.puts "end"
end


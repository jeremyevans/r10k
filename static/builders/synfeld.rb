synfeld_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "    add_route '#{prefix}#{base}', :action => :#{prefix.gsub('/', '_') unless prefix.empty?}#{base}"
    else
      synfeld_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

synfeld_methods = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  def #{prefix.gsub('/', '_') unless prefix.empty?}#{base}"
      f.puts "    '#{RESULT.call(prefix[1..-1] + base)}'"
      f.puts "  end"
    else
      synfeld_methods.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/synfeld_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'synfeld'"
  f.puts "class AppClass < Synfeld::App"
  f.puts "  def add_routes"
  synfeld_routes.call(f, LEVELS, '/')
  f.puts "  end"
  synfeld_methods.call(f, LEVELS, '/')
  f.puts "end"
  f.puts "o = Object.new"
  f.puts "def o.method_missing(*) end"
  f.puts "App = AppClass.new(:logger=>o, :root_dir=>File.dirname(__FILE__)).as_rack_app"
end

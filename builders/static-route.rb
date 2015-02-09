static_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "    def #{prefix}#{'_' unless prefix.empty?}#{base}"
      f.puts "      @body = '#{RESULT.call(prefix.gsub('_', '/') + (prefix.empty? ? '' : '/') + base)}'"
      f.puts "    end"
    else
      static_routes.call(f, level-1, "#{prefix}#{'_' unless prefix.empty?}#{base}")
    end
    base.succ!
  end
end

matcher = '(?:\\/([^\\/]*))?'
File.open("#{File.dirname(__FILE__)}/../apps/static-route_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "class App"
  f.puts "  class << self"
  f.puts "    def call(env)"
  f.puts "      send env['PATH_INFO'].match(/\\A#{matcher * LEVELS}\\z/).captures.join('_')"
  f.puts "      finish"
  f.puts "    end"
  f.puts "    def finish"
  f.puts "      [200, {'Content-Type'=>'text/html', 'Content-Length'=>@body.length.to_s}, [@body]]"
  f.puts "    end"
  static_routes.call(f, LEVELS, '')
  f.puts "  end"
  f.puts "end"
end



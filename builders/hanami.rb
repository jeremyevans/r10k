hanami_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  controller = prefix.gsub('/', '_')
  controller = 'main' if controller.empty?
  spaces = "  " * (LEVELS - level + 1)
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "#{spaces}  get '/#{base}', :to=>'h_#{controller}##{base}'"
    else
      f.puts "#{spaces}namespace '#{base}' do"
      hanami_routes.call(f, level-1, "#{prefix}#{'/' unless prefix.empty?}#{base}")
      f.puts "#{spaces}end"
    end
    base.succ!
  end
end

hanami_controllers = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  if level == 1
    f.puts "module H#{prefix.empty? ? 'Main' : prefix}"
    ROUTES_PER_LEVEL.times do
      f.puts "  class #{base.upcase}"
      f.puts "    include Hanami::Action"
      f.puts "    def call(params)"
      f.puts "      res = '#{RESULT.call((prefix + base).downcase.split(//).join('/'))}'"
      f.puts "      headers['Content-Type'] = 'text/html'"
      f.puts "      headers['Content-Length'] = res.length.to_s"
      f.puts "      self.body = res"
      f.puts "    end"
      f.puts "  end"
      base.succ!
    end
    f.puts "end"
  else
    ROUTES_PER_LEVEL.times do
      hanami_controllers.call(f, level-1, "#{prefix}#{base.upcase}")
      base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/hanami_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'hanami/router'"
  f.puts "require 'hanami/controller'"
  hanami_controllers.call(f, LEVELS, '')
  f.puts "App = Hanami::Router.new do"
  hanami_routes.call(f, LEVELS, '')
  f.puts "end"
end

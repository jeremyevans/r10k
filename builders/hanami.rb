hanami_routes = lambda do |f, level, prefix, lvars|
  base = BASE_ROUTE.dup
  controller = prefix.gsub('/', '').gsub(/:\w/, '')
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}/:#{lvars.last}', :to=>Main::#{(controller + base).capitalize}.new"
    else
      hanami_routes.call(f, level-1, "#{prefix}#{base}/:#{lvars.last}/", lvars + [lvars.last.succ])
    end
    base.succ!
  end
end

hanami_controllers = lambda do |f, level, prefix, class_prefix, calc_path, lvars|
  base = BASE_ROUTE.dup
  if level == 1
    ROUTES_PER_LEVEL.times do
      f.puts "  class #{(class_prefix + base).capitalize}"
      f.puts "    include Hanami::Action"
      f.puts "    def handle(req, res)"
      f.puts "      body = \"#{RESULT.call(calc_path + base)}#{lvars.map{|lvar| "-\#{req.params[:#{lvar}]}"}.join}\""
      f.puts "      res.headers['Content-Type'] = 'text/html'"
      f.puts "      res.headers['Content-Length'] = body.length.to_s"
      f.puts "      res.body = body"
      f.puts "    end"
      f.puts "  end"
      base.succ!
    end
  else
    ROUTES_PER_LEVEL.times do
      hanami_controllers.call(f, level-1, "#{prefix}#{base.upcase}/:#{lvars.last}/", "#{class_prefix}#{base}", "#{calc_path}#{base}/", lvars + [lvars.last.succ])
      base.succ!
    end
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/hanami_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen-string-literal: true"
  f.puts "require 'hanami/router'"
  f.puts "require 'hanami/controller'"
  f.puts "module Main"
  hanami_controllers.call(f, LEVELS, '', '', '', ['a'])
  f.puts "end"
  f.puts "App = Hanami::Router.new do"
  hanami_routes.call(f, LEVELS, '/', ['a'])
  f.puts "end"
end

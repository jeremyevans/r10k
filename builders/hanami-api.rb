hanami_routes = lambda do |f, level, prefix, calc_path, lvars|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}/:#{lvars.last}'  do"
      f.puts "    body = \"#{RESULT.call(calc_path[1..-1] + base)}#{lvars.map{|lvar| "-\#{params[:#{lvar}]}"}.join}\""
      f.puts "    headers['Content-Type'] = 'text/html'"
      f.puts "    headers['Content-Length'] = body.length.to_s"
      f.puts "    body"
      f.puts "  end"
    else
      hanami_routes.call(f, level-1, "#{prefix}#{base}/:#{lvars.last}/", "#{calc_path}#{base}/", lvars + [lvars.last.succ])
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/hanami-api_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "# frozen_string_literal: true"
  f.puts "require 'hanami/api'"
  f.puts "class API < Hanami::API"
  hanami_routes.call(f, LEVELS, '/', '/', ['a'])
  f.puts "end"
  f.puts "App = API.new"
end

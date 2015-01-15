#!/usr/bin/env ruby

require 'benchmark'

integer = proc{|path| path.split(//).map{|c| c.ord.to_s}.join}

app = ARGV.first
File.basename(app) =~ /\A([-a-z]+)_(\d+)_(\d+)\.rb\z/
type, levels, routes_per_level = $1, $2.to_i, $3.to_i
base_route = 'a'.freeze
env = {"REQUEST_METHOD" => "GET".freeze, "SCRIPT_NAME" => "".freeze, "rack.input"=>File.open('/dev/null')}
path_info = "PATH_INFO".freeze

ENV['RAILS_ENV'] = 'production'
ENV['RACK_ENV'] = 'production'
require "./#{app}"
app = App

class Rack::BodyProxy
  def join
    a = []
    each{|s| a << s}
    a.join
  end
end

if ENV['CHECK']
  request_routes = lambda do |prefix, level|
    b = base_route.dup
    routes_per_level.times do
      e = env.dup
      path = e[path_info] = "#{prefix}#{b}"
      if level == 1
        unless (was = app.call(e).last.join) == integer.call(path)
          raise "route body does not match expected value for path: #{path}, expected: #{integer.call(path)}, actual: #{was}}"
        end
      else
        request_routes.call("#{prefix}#{b}/", level - 1)
      end
      b.succ!
    end
  end
else
  request_routes = lambda do |prefix, level|
    b = base_route.dup
    routes_per_level.times do
      e = env.dup
      path = e[path_info] = "#{prefix}#{b}"
      if level == 1
        app.call(e)
      else
        request_routes.call("#{prefix}#{b}/", level - 1)
      end
      b.succ!
    end
  end
end

n = 20000/(routes_per_level ** levels)
puts Benchmark.measure{n.times{request_routes.call("/", levels)}}.real

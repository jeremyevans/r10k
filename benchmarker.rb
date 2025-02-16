#!/usr/bin/env ruby

require 'benchmark'

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

if defined?(Rack::BodyProxy)
  class Rack::BodyProxy
    def join
      a = []
      each{|s| a << s}
      a.join
    end
  end
end

vars = levels.times.map{sprintf("%06i", (rand*1000000).floor)}
expected_suffix = "-#{vars.join('-')}"

all_routes = []
RESULT = proc{|path| path.split(//).map{|c| c.ord.to_s}.join}

request_routes = lambda do |prefix, level, calc_path, vars|
  b = base_route.dup
  var, *vars = vars
  routes_per_level.times do
    e = env.dup
    path = e[path_info] = "#{prefix}#{b}/#{var}"
    if level == 1
      all_routes << [e, RESULT.call("#{calc_path}#{b}") + expected_suffix]
    else
      request_routes.call("#{prefix}#{b}/#{var}/", level - 1, "#{calc_path}#{b}/", vars)
    end
    b.succ!
  end
end
request_routes.call("/", levels, "/", vars)

if ENV['CHECK']
  basic_checks = lambda do
    e, _ = all_routes[0]
    res = app.call(e.merge('PATH_INFO'=>e['PATH_INFO'].gsub(/\d+\z/, '')))
    if res[0] != 404
      raise "route did not return 404 status for path: #{e['PATH_INFO'][0...-1]}, status: #{res[0]}"
    end
    res = app.call(e.merge('PATH_INFO'=>e['PATH_INFO'] + '/'))
    if res[0] != 404
      warn "warning: route did not return 404 status for trailing slash for path: #{e['PATH_INFO']}/, status: #{res[0]}"
    end
    res = app.call(e.merge('REQUEST_METHOD'=>'POST'))
    if ![404, 405, 501].include?(res[0])
      raise "route did not return 404 or 405 status for POST request to path: #{e['PATH_INFO']}, status: #{res[0]}"
    end
  end.call

  run_routes = lambda do
    all_routes.each do |e, expected|
      res = app.call(Hash[e])
      unless (body = res.last.join) == expected
        raise "route body does not match expected value for path: #{e['PATH_INFO']}, expected: #{expected}, actual: #{body}}"
      end
      unless res[0] == 200
        raise "route did not return 200 status for path: #{e['PATH_INFO']}, status: #{res[0]}"
      end
      unless res[1]['Content-Type'] =~ /text\/html/
        raise "route did not use text/html content type for path: #{e['PATH_INFO']}, Content-Type: #{res[1]['Content-Type']}"
      end
      unless res[1]['Content-Length'] == expected.length.to_s
        raise "route did not use correct content length for path: #{e['PATH_INFO']}, expected: #{expected.length}, actual: #{res.inspect}"
      end
    end
  end
else
  all_routes.map!(&:first)
  run_routes = lambda do
    all_routes.each do |e|
      app.call(Hash[e])
    end
  end
end

unless (n = ENV['R10K_ITERATIONS'].to_i) > 0
  n = 2
end
n *= (10000.0/(routes_per_level ** levels)).ceil

if defined?(RubyVM::YJIT.enable) && ENV.fetch('R10K_YJIT', 'true') == 'true'
  RubyVM::YJIT.enable
end

if (warmup = ENV['R10K_WARMUP_ITERATIONS'].to_i) > 0
  warmup.times{run_routes.call}
end

bm = if (threads = ENV['R10K_NUM_THREADS'].to_i) > 0
  queue = Queue.new
  n.times{queue.push(true)}
  threads.times{queue.push(nil)}
  Benchmark.measure do
    (0...threads).map do
      Thread.new do
        while pr = queue.pop
          run_routes.call
        end
      end
    end.map(&:join)
  end
else
  Benchmark.measure{n.times{run_routes.call}}
end

puts((all_routes.size * n) / bm.real)

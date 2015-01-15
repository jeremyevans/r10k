#!/usr/bin/env ruby

ROUTES_PER_LEVEL = (ARGV.pop || 10).to_i
LEVELS = (ARGV.pop || 5).to_i
BASE_ROUTE = 'a'.freeze
RESULT = proc{|path| "/#{path}".split(//).map{|c| c.ord.to_s}.join}

require "./builders/#{ARGV.pop}"

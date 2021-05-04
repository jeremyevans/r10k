#!/usr/bin/env ruby

dir, app_type, num_levels, per_level = ARGV
ROUTES_PER_LEVEL = (per_level || 10).to_i
LEVELS = (num_levels || 4).to_i
BASE_ROUTE = 'a'.freeze
RESULT = proc{|path| "/#{path}".split(//).map{|c| c.ord.to_s}.join}

require "./#{dir}builders/#{app_type}"

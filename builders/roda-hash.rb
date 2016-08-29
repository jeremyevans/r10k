roda_hash_routes = lambda do |f, level, prefix|
  base = BASE_ROUTE.dup
  ROUTES_PER_LEVEL.times do
    if level == 1
      f.puts "  get '#{prefix}#{base}' do |r|"
      f.puts "    '#{RESULT.call(prefix[1..-1] + base)}'"
      f.puts "  end"
    else
      roda_hash_routes.call(f, level-1, "#{prefix}#{base}/")
    end
    base.succ!
  end
end

File.open("#{File.dirname(__FILE__)}/../apps/roda-hash_#{LEVELS}_#{ROUTES_PER_LEVEL}.rb", 'wb') do |f|
  f.puts "require 'roda'"
  f.puts "class App < Roda"
  f.puts "  @routes = {}"
  f.puts "  @routes['GET'] = {}"
  f.puts "  class << self; attr_reader :routes; end"
  f.puts "  def self.get(route, &block)"
  f.puts "    @routes['GET'][route] = block"
  f.puts "  end"
  roda_hash_routes.call(f, LEVELS, '/')
  f.puts "  route do |r|"
  f.puts "    if (h = self.class.routes[r.request_method]) && (b = h[r.remaining_path])"
  f.puts "      instance_exec(r, &b)"
  f.puts "    end"
  f.puts "  end"
  f.puts "end"
end

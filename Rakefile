APPS = ENV['R10K_APPS'] ? ENV['R10K_APPS'].split : %w'static-route syro roda nyny cuba hanami rails sinatra synfeld'
RANGE = 1..(ENV['LEVELS'] || 4).to_i
ROUTES_PER_LEVEL = (ENV['ROUTES_PER_LEVEL'] || 10)

require 'rake/clean'
desc "build the app file"
task :build do
  Dir.mkdir 'apps' unless File.directory?('apps')
  APPS.each do |app|
    RANGE.each do |i|
      sh "#{FileUtils::RUBY} builder.rb #{app} #{i} #{ROUTES_PER_LEVEL}"
    end
  end
end

desc "benchmark apps, creating csv data files"
task :bench => [:build] do
  apps = {}
  APPS.each do |app|
    times = apps[app] = {}
    RANGE.each do |i|
      runtimes = []
      runtimes_with_startup = []
      memory = []
      3.times do |j|
        file = "apps/#{app}_#{i}_#{ROUTES_PER_LEVEL}.rb"
        puts "running #{file}, pass #{j+1}"
        t = Time.now
        runtimes << `#{FileUtils::RUBY} benchmarker.rb #{file}`.to_f
        runtimes_with_startup << Time.now - t
        memory << `#{FileUtils::RUBY} -r ./#{file}  -e 'GC.start; system("ps -o rss -p \#{$$}")'`.split.last.to_i
      end
      times[i] = [runtimes.min, runtimes_with_startup.min, memory.min]
    end
  end

  Dir.mkdir 'data' unless File.directory?('data')
  %w'runtime.csv runtime_with_startup.csv memory.csv'.each_with_index do |file, j|
    File.open("data/#{file}", 'wb') do |f|
      headers = %w'app'
      RANGE.each do |i|
        headers << ROUTES_PER_LEVEL**i
      end
      f.puts headers.join(',')

      apps.each do |app, times|
        row = [app]
        RANGE.each do |i|
          row << times[i][j].to_s
        end
        f.puts row.join(',')
      end
    end
  end
end

run_graphs = lambda do |columns|
  require 'gruff'
  Dir.mkdir 'graphs' unless File.directory?('graphs')

  [
    ['runtime', 'Runtime for 20,000 Requests'],
    ['runtime_with_startup', 'Runtime inc. Startup for 20,000 Requests'],
    ['memory', 'Initial Memory Usage'],
  ].each do |file, title|
    g = Gruff::Line.new(ENV['DIM'] || '1280x720')
    g.legend_font_size = ENV['LEGEND_FONT_SIZE'].to_i if ENV['LEGEND_FONT_SIZE']
    g.title = title
    labels = {}
    0.upto(columns-1){|i| labels[i] = (ROUTES_PER_LEVEL**(i+1)).to_s}
    g.labels = labels
    g.x_axis_label = 'Number of Routes'
    g.y_axis_label = file == 'memory' ? 'RSS (MB)' : 'Seconds'
    max = 0
    File.read("data/#{file}.csv").split("\n")[1..-1].map{|l| l.split(',')}.each do |app, *data|
      data = data[0...columns]
      file == 'memory' ? data.map!{|x| x.to_f / 1024.0} : data.map!{|x| x.to_f}
      dmax = data.max
      max = dmax if dmax > max
      g.data app.capitalize, data
    end
    g.y_axis_increment = if max < 10 then 1
    elsif max < 20 then 5
    elsif max < 50 then 10
    elsif max < 100 then 20
    elsif max < 200 then 50
    else 100
    end
    g.minimum_value = 0
    g.write("graphs/#{file}#{"_#{columns}" unless columns == 4}.png")
  end
end

desc "create graphs using csv data files"
task :graphs do
  run_graphs.call(RANGE.end)
end

desc "create graphs using csv data files, ignoring final level"
task :graphs_3 do
  run_graphs.call(RANGE.end-1)
end

IO.readlines(".gitignore").each do |glob|
  CLOBBER << FileList[glob.strip]
end

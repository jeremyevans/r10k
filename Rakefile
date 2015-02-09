APPS = ENV['R10K_APPS'] ? ENV['R10K_APPS'].split : %w'roda roda-run roda-multi-route cuba rails sinatra'
RANGE = 1..4

require 'rake/clean'
desc "build the app file"
task :build do
  Dir.mkdir 'apps' unless File.directory?('apps')
  APPS.each do |app|
    RANGE.each do |i|
      sh "#{FileUtils::RUBY} builder.rb #{app} #{i} #{10}"
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
        file = "apps/#{app}_#{i}_10.rb"
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
        headers << 10**i
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
    g.title = title
    labels = {}
    0.upto(columns-1){|i| labels[i] = (10**(i+1)).to_s}
    g.labels = labels
    g.x_axis_label = 'Number of Routes'
    g.y_axis_label = file == 'memory' ? 'RSS (MB)' : 'Seconds'
    max = nil
    File.read("data/#{file}.csv").split("\n")[1..-1].map{|l| l.split(',')}.each do |app, *data|
      file == 'memory' ? data.map!{|x| x.to_f / 1024.0} : data.map!{|x| x.to_f}
      max = data.max
      g.data app.capitalize, data[0...columns].map{|x| x.to_f}
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
  run_graphs.call(4)
end

desc "create graphs using csv data files, ignoring 10,000 requests"
task :graphs_3 do
  run_graphs.call(3)
end

IO.readlines(".gitignore").each do |glob|
  CLOBBER << FileList[glob.strip]
end

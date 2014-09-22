desc "build the app file"
task :apps do
  (1..4).each do |i|
    sh "./large_apps.rb #{i} #{10}"
  end
end

desc "benchmark apps, creating csv data files"
task :bench do
  apps = {}
  range = 1..4
  %w'roda rails sinatra'.each do |app|
    times = apps[app] = {}
    range.each do |i|
      runtimes = []
      runtimes_with_startup = []
      memory = []
      3.times do |j|
        file = "#{app}_#{i}_10.rb"
        puts "running #{file}, pass #{j+1}"
        t = Time.now
        runtimes << `./benchmarker.rb #{file}`.to_f
        runtimes_with_startup << Time.now - t
        memory << `#{FileUtils::RUBY} -r ./#{file}  -e 'GC.start; system("ps -o rss -p \#{$$}")'`.split.last.to_i
      end
      times[i] = [runtimes.min, runtimes_with_startup.min, memory.min]
    end
  end

  %w'runtime.csv runtime_with_startup.csv memory.csv'.each_with_index do |file, j|
    File.open(file, 'wb') do |f|
      headers = %w'app'
      range.each do |i|
        headers << 10**i
      end
      f.puts headers.join(',')

      apps.each do |app, times|
        row = [app]
        range.each do |i|
          row << times[i][j].to_s
        end
        f.puts row.join(',')
      end
    end
  end
end

desc "create graphs using csv data files"
task :graphs do
  require 'gruff'
  [['runtime.csv', 'Runtime for 20,000 Requests'],
   ['runtime_with_startup.csv', 'Runtime inc. Startup for 20,000 Requests'],
   ['memory.csv', 'Initial Memory Usage'],
  ].each do |file, title|
    g = Gruff::Line.new('1280x720')
    g.title = title
    g.labels = {0=>'10', 1=>'100', 2=>'1000', 3=>'10000'}
    g.x_axis_label = 'Number of Routes'
    g.y_axis_label = file == 'memory.csv' ? 'RSS (MB)' : 'Seconds'
    g.y_axis_increment = file == 'memory.csv' ? 50 : 100
    File.read(file).split("\n")[1..-1].map{|l| l.split(',')}.each do |app, *data|
      data.map!{|x| x.to_f / 1024.0} if file == 'memory.csv'
      g.data app.capitalize, data.map{|x| x.to_f}
    end
    g.minimum_value = 0
    g.write(file.sub('csv', 'png'))
  end
end

desc "create graphs using csv data files, ignoring 10,000 requests"
task :graphs_3 do
  require 'gruff'
  [['runtime.csv', 'Runtime for 20,000 Requests'],
   ['runtime_with_startup.csv', 'Runtime inc. Startup for 20,000 Requests'],
   ['memory.csv', 'Initial Memory Usage'],
  ].each do |file, title|
    g = Gruff::Line.new('1280x720')
    g.title = title
    g.labels = {0=>'10', 1=>'100', 2=>'1000'}
    g.x_axis_label = 'Number of Routes'
    g.y_axis_label = file == 'memory.csv' ? 'RSS (MB)' : 'Seconds'
    g.y_axis_increment = 10
    File.read(file).split("\n")[1..-1].map{|l| l.split(',')}.each do |app, *data|
      data.map!{|x| x.to_f / 1024.0} if file == 'memory.csv'
      g.data app.capitalize, data[0...-1].map{|x| x.to_f}
    end
    g.minimum_value = 0
    g.write(file.sub('.csv', '_3.png'))
  end
end

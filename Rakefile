APPS = ENV['R10K_APPS'] ? ENV['R10K_APPS'].split : %w'rails roda cuba hanami'
RANGE = 1..(ENV['LEVELS'] || 4).to_i
ROUTES_PER_LEVEL = (ENV['ROUTES_PER_LEVEL'] || 10).to_i

require 'rake/clean'
CLEAN.include(IO.read(".gitignore").split.to_a.map do |f|
  f = f[1..-1] if f.start_with?('/')
  f.strip
end)

[[:dynamic, "", ""], [:static, "static_", "static/"]].each do |test_type, rake_prefix, dir|
  apps_dir = "#{dir}apps"
  data_dir = "#{dir}data"
  graphs_dir = "#{dir}graphs"

  desc "build the app file"
  task "#{rake_prefix}build" do
    Dir.mkdir apps_dir unless File.directory?(apps_dir)
    APPS.each do |app|
      RANGE.each do |i|
        sh "#{FileUtils::RUBY} builder.rb '#{dir}' #{app} #{i} #{ENV['CHECK'] ? 2 : ROUTES_PER_LEVEL}"
      end
    end
  end

  desc "check apps return correct results"
  task "#{rake_prefix}check" do
    ENV['CHECK'] = '1'
    Rake::Task["#{rake_prefix}bench"].invoke
  end

  desc "benchmark apps, creating csv data files"
  task "#{rake_prefix}bench" => "#{rake_prefix}build" do
    apps = {}
    checking = ENV['CHECK']
    APPS.each do |app|
      metrics = apps[app] = {}
      RANGE.each do |i|
        rpss = []
        runtimes_with_startup = []
        memory = []
        routes_per_level = checking ? 2 : ROUTES_PER_LEVEL
        (checking ? 1 : 3).times do |j|
          file = "#{apps_dir}/#{app}_#{i}_#{routes_per_level}.rb"
          send(checking ? :puts : :print, "running #{file}, pass #{j+1}")
          t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          rps = `#{FileUtils::RUBY} #{dir}benchmarker.rb #{file}`.to_f

          next if checking

          rpss << rps 
          puts ", #{rps.to_i} requests/second"
          runtimes_with_startup << Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
          memory << `#{FileUtils::RUBY} -r ./#{file}  -e 'GC.start; system("ps -o rss -p \#{$$}")'`.split.last.to_i
        end
        metrics[i] = [rpss.max, runtimes_with_startup.min, memory.min]
      end
    end

    if checking
      puts "Ran in check mode, not writing data files"
      next
    end

    Dir.mkdir data_dir unless File.directory?(data_dir)
    %w'rps.csv runtime_with_startup.csv memory.csv'.each_with_index do |file, j|
      File.open("#{data_dir}/#{file}", 'wb') do |f|
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
    Dir.mkdir graphs_dir unless File.directory?(graphs_dir)

    [
      ['rps', 'Requests/Second', :to_f.to_sym],
      ['log_rps', 'Log10 Requests/Second', proc{|x| Math.log10(x.to_f)}],
      ['runtime_with_startup', 'Runtime inc. Startup', :to_f.to_sym],
      ['memory', 'Initial Memory Usage', proc{|x| x.to_f / 1024.0}],
    ].each do |type, title, convertor|
      g = Gruff::Line.new(ENV['DIM'] || '1920x1080')
      g.legend_font_size = ENV['LEGEND_FONT_SIZE'].to_i if ENV['LEGEND_FONT_SIZE']
      if mv = ENV["MAXIMUM_VALUE_#{type.upcase}"]
        g.maximum_value = mv.to_i
      end
      g.title = title
      labels = {}
      0.upto(columns-1){|i| labels[i] = (ROUTES_PER_LEVEL**(i+1)).to_s}
      g.labels = labels
      g.x_axis_label = 'Number of Routes'
      g.y_axis_label = case type
      when 'rps'
        'R/S'
      when 'log_rps'
        'Log10 R/S'
      when 'runtime_with_startup'
        'Seconds'
      when 'memory'
        'RSS (MB)'
      end
      max = 0
      file = type == 'log_rps' ? 'rps' : type
      File.read("#{data_dir}/#{file}.csv").split("\n")[1..-1].map{|l| l.split(',')}.each do |app, *data|
        data = data[0...columns]
        data.map!(&convertor)
        dmax = data.max
        max = dmax if dmax > max
        g.data app.capitalize, data
      end
      g.y_axis_increment = if max < 10 then 1
      elsif max < 100 then 10
      elsif max < 1000 then 100
      elsif max < 10000 then 1000
      elsif max < 140000 then 10000
      else 20000
      end
      g.minimum_value = 0
      g.write("#{graphs_dir}/#{type}#{"_#{columns}" unless columns == 4}.png")
    end
  end

  desc "create graphs using csv data files"
  task "#{rake_prefix}graphs" do
    run_graphs.call(RANGE.end)
  end

  desc "create graphs using csv data files, ignoring final level"
  task "#{rake_prefix}graphs3" do
    run_graphs.call(RANGE.end-1)
  end
end

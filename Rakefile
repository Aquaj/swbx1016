namespace :assets do
  task :precompile do
    sh 'middleman build --verbose'
  end
end

namespace :env do
  task :push do
    File.readlines(args[:env_file]).map(&:strip).each do |value|
      next if value.first '#'
      Kernel.system "heroku config:set #{value}"
    end
  end
end

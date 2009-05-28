require 'rubygems'
require 'rake'
require 'net/http'
require 'active_record'
require "#{File.dirname(__FILE__)}/../config/environment.rb"

namespace :solr do

  desc 'Starts Solr. Options accepted: PID_PATH, RAILS_ENV, SOLR_HOME'
  task :start => :environment do

    plugin_path = File.dirname(__FILE__) + "/../solr"

    unless File.exists?( File.join( plugin_path, 'logs' ) )
      Dir.mkdir( File.join( plugin_path, 'logs' ) )
    end

    begin
      n = Net::HTTP.new( SOLR_HOST , SOLR_PORT)
      n.request_head('/').value 

    rescue Net::HTTPServerException #responding
      puts "Port #{SOLR_PORT} in use" and return

    rescue Errno::ECONNREFUSED, Errno::ENETUNREACH #not responding
      Dir.chdir( plugin_path ) do
        pid = fork do
          exec "java -Dsolr.solr.home=#{SOLR_PATH} -Dsolr.data.dir=#{SOLR_PATH}/data/#{RAILS_ENV} -Djetty.host=#{SOLR_HOST} -Djetty.port=#{SOLR_PORT} -jar start.jar"
        end
        sleep(5)
        pid_path = ENV['PID_PATH'] || "#{RAILS_ROOT}/tmp/pids/solr_#{RAILS_ENV}.pid"
        File.open( pid_path , "w"){ |f| f << pid}
        puts "#{ENV['RAILS_ENV']} Solr started successfully on #{SOLR_PORT}, pid: #{pid}."
      end
    end
  end
  
  desc 'Stops Solr. Options accepted: PID_PATH, RAILS_ENV, SOLR_HOME'
  task :stop => :environment do
    fork do
      pid_path = ENV['PID_PATH'] || "#{RAILS_ROOT}/tmp/pids/solr_#{RAILS_ENV}.pid"
      if File.exists?(pid_path)
        File.open(pid_path, "r") do |f|
          pid = f.readline
          Process.kill('TERM', pid.to_i)
        end
        File.unlink(pid_path)
        Rake::Task["solr:destroy_index"].invoke if RAILS_ENV == 'test'
        puts "Solr shutdown successfully."
      else
        puts "Solr is not running.  I haven't done anything."
      end
    end
  end
  
  desc 'Remove Solr index'
  task :destroy_index => :environment do
    if File.exists?("#{SOLR_PATH}data/#{RAILS_ENV}")
      Dir[ SOLR_PATH + "data/#{RAILS_ENV}/index/*"].each{|f| File.unlink(f)}
      Dir.rmdir(SOLR_PATH + "/data/#{RAILS_ENV}/index")
      puts "Index files removed under " + RAILS_ENV + " environment"
    end
  end

  desc 'Rebuild solr index'
  task :rebuild_index => :environment do
    
    if ENV['start'].blank?
      ActsAsSolr::Post.rebuild_indexes
    else
      ActsAsSolr::Post.rebuild_indexes( 100 ) do |ar, options|
        ar.all(options.merge({:order => 'id', :conditions => [ 'updated_at > ?', ENV['start'].to_i.days.ago ]}))
      end
    end
    
  end

  desc 'Setup solr environment'
  task :setup => :environment do
    plugin_path = File.dirname(__FILE__) + "/../solr"
    system "mkdir -p #{plugin_path}/logs && mkdir -p #{plugin_path}/tmp"
    Rake::Task["solr:start"].invoke
    sleep(5)
    ActsAsSolr::Post.rebuild_indexes
  end

end

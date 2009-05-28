require 'fileutils'

def install(file)
  puts "Installing: #{file}"
  target = File.join(File.dirname(__FILE__), '..', '..', '..', file)
  FileUtils.cp File.join(File.dirname(__FILE__), file), target
  dir_to_rename = File.dirname(__FILE__) + '/../trunk'
  FileUtils.mv(dir_to_rename, File.dirname(__FILE__) + '/../acts_as_solr') if File.exists? dir_to_rename
end

install File.join( 'config', 'solr.yml' )

unless File.exists?( "#{RAILS_ROOT}/config/solr" )
  Dir.mkdir( File.join(RAILS_ROOT, 'config', 'solr') )
  solr_dir = File.join( File.dirname(__FILE__), 'solr', 'solr', 'conf' )
  FileUtils.cp_r( solr_dir, File.join(RAILS_ROOT, 'config', 'solr', 'conf') )
end
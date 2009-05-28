SOLR_PATH = ENV['SOLR_HOME'] || "#{RAILS_ROOT}/config/solr"

port = 8982
host = 'localhost'

if File.exists?( "#{RAILS_ROOT}/config/solr.yml" )
  solr_config = YAML.load( IO.read("#{RAILS_ROOT}/config/solr.yml") )[ RAILS_ENV ]
  unless solr_config.blank?
    config = solr_config['url'].gsub( 'http://', '' ).split( '/' ).first.split(':')
    host = config.first
    port = config.last.to_i
  end
end

SOLR_HOST = host
SOLR_PORT = port

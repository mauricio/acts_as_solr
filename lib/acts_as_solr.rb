# Copyright (c) 2006 Erik Hatcher, Thiago Jackiw
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'active_record'
require 'rexml/document'
require 'net/http'
require 'yaml'

require File.dirname(__FILE__) + '/solr'
require File.dirname(__FILE__) + '/acts_methods'
require File.dirname(__FILE__) + '/class_methods'
require File.dirname(__FILE__) + '/instance_methods'
require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/deprecation'
require File.dirname(__FILE__) + '/search_results'

module ActsAsSolr
  
  class Post

    @@indexed_classes = []
    @@solr_configuration = {:url => 'http://localhost:8982/solr' }
    cattr_accessor :indexed_classes
    cattr_accessor :solr_configuration

    class << self

      def error_handler(&block)
        if block_given?
          @error_handler = block
        else
          @error_handler
        end
      end

      def error_handler=( new_handler )
        @error_handler = new_handler
      end

      def handle_error( ex )
        if @error_handler
          @error_handler.call( ex )
        end
      end

      def execute(request)
        Solr::Connection.new( solr_configuration[:url] ).send(request)
      end

      def rebuild_indexes( batch_size = 100, &finder )
        puts "Rebuilding indexes for -> #{indexed_classes.inspect}"
        indexed_classes.each do |c|
          c.rebuild_solr_index( batch_size, &finder )
        end
        true
      end

      def optimize_indexes
        puts "Optimizing indexes for -> #{indexed_classes.inspect}"
        indexed_classes.each do |c|
          c.solr_optimize
        end
        true
      end

    end

  end
  
end

# reopen ActiveRecord and include the acts_as_solr method
ActiveRecord::Base.extend ActsAsSolr::ActsMethods

solr_file_path = File.join( RAILS_ENV, 'config', 'solr.yml' )

if File.exists?( solr_file_path )
  ActsAsSolr::Post.solr_configuration = YAML::load_file( solr_file_path )[RAILS_ENV].symbolize_keys
end

if ActsAsSolr::Post.solr_configuration[:raise_error].blank? || ActsAsSolr::Post.solr_configuration[:raise_error].strip.downcase == 'false'
  ActsAsSolr::Post.solr_configuration[:raise_error] = false
else
  ActsAsSolr::Post.solr_configuration[:raise_error] = true
end
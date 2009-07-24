module ActsAsSolr #:nodoc:
  
  module ActsMethods
    
    # declares a class as solr-searchable
    #
    # Calling acts_as_solr alone in your ActiveRecord object will make all
    # fields that are not the primary key, updated_at and created_at
    # indexed fields.
    #
    #            class NewsStory < ActiveRecord::Base
    #              acts_as_solr # this will index all user fields
    #                           # leaving out the id, updated_at and created_at
    #            end
    #
    #
    # ==== options:
    # fields:: This option can be used to specify only the fields you'd
    #          like to index. If not given, all the attributes from the 
    #          class will be indexed. You can also use this option to 
    #          include methods that should be indexed as fields
    # 
    #           class Movie < ActiveRecord::Base
    #             acts_as_solr :fields => [:name, :description, :current_time]
    #             def current_time
    #               Time.now.to_s
    #             end
    #           end
    #          
    #          Each field passed can also be a hash with the value being a field type
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => :range_float}]
    #             def current_time
    #               Time.now
    #             end
    #           end
    # 
    #          The field types accepted are:
    # 
    #          :float:: Index the field value as a float (ie.: 12.87)
    #          :integer:: Index the field value as an integer (ie.: 31)
    #          :boolean:: Index the field value as a boolean (ie.: true/false)
    #          :date:: Index the field value as a date (ie.: Wed Nov 15 23:13:03 PST 2006)
    #          :string:: Index the field value as a text string, not applying the same indexing
    #                    filters as a regular text field
    #          :range_integer:: Index the field value for integer range queries (ie.:[5 TO 20])
    #          :range_float:: Index the field value for float range queries (ie.:[14.56 TO 19.99])
    # 
    #          Setting the field type preserves its original type when indexed
    # 
    # 
    # exclude_fields:: This option taks an array of fields that should be ignored from indexing:
    # 
    #                    class User < ActiveRecord::Base
    #                      acts_as_solr :exclude_fields => [:password, :login, :credit_card_number]
    #                    end
    # 
    # include:: This option can be used for association indexing, which 
    #           means you can include any :has_one, :has_many, :belongs_to 
    #           and :has_and_belongs_to_many association to be indexed:
    # 
    #            class Category < ActiveRecord::Base
    #              has_many :books
    #              acts_as_solr :include => [:books]
    #            end
    # 
    # facets:: This option can be used to specify the fields you'd like to
    #          index as facet fields
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :facets => [:category, :manufacturer]  
    #           end
    # 
    # boost:: You can pass a boost (float) value that will be used to boost the document and/or a field:
    # 
    #           class Electronic < ActiveRecord::Base
    #             acts_as_solr :fields => [{:price => {:boost => 5.0}}], :boost => 10.0
    #           end
    # 
    # if:: Only indexes the record if the condition evaluated is true. The argument has to be 
    #      either a symbol, string (to be eval'ed), proc/method, or class implementing a static 
    #      validation method. It behaves the same way as ActiveRecord's :if option.
    # 
    #        class Electronic < ActiveRecord::Base
    #          acts_as_solr :if => proc{|record| record.is_active?}
    #        end
    # 
    # auto_commit:: The commit command will be sent to Solr only if its value is set to true:
    # 
    #                 class Author < ActiveRecord::Base
    #                   acts_as_solr :auto_commit => false
    #                 end
    #
    # error_handler:: A proc that is going to receive the errors generated
    #                 when trying to index or search for objects from this
    #                 class (optional):
    #
    #                 class Author < ActiveRecord::Base
    #                   acts_as_solr :error_handler => proc { |ex| puts ex.inspect }
    #                 end
    #
    def acts_as_solr(options={}, solr_options={})
      
      extend ClassMethods
      include InstanceMethods
      include CommonMethods
      include ParserMethods

      ActsAsSolr::Post.indexed_classes << self

      cattr_accessor :acts_as_solr_configuration
      cattr_accessor :solr_configuration
      
      self.acts_as_solr_configuration = {
        :fields => nil,
        :exclude_fields => [],
        :auto_commit => false,
        :include => nil,
        :facets => nil,
        :boost => nil,
        :if => "true",
        :error_handler => nil
      }  
      self.solr_configuration = {
        :type_field => "type_t",
        :primary_key_field => "pk_i",
        :default_boost => 1.0
      }
      
      acts_as_solr_configuration.update(options) if options.is_a?(Hash)
      solr_configuration.update(solr_options) if solr_options.is_a?(Hash)
      Deprecation.validate_index(acts_as_solr_configuration)
      
      acts_as_solr_configuration[:solr_fields] = []
      
      after_save    :solr_save
      after_destroy :solr_destroy

      if acts_as_solr_configuration[:fields].respond_to?(:each)
        process_fields(acts_as_solr_configuration[:fields])
      else
        process_fields((self.column_names - [ self.primary_key, 'updated_at', 'created_at' ]).map { |k| k.to_sym })
      end

    end
    
    private

    def get_field_value(field)
      acts_as_solr_configuration[:solr_fields] << field
      type  = if field.is_a?( Hash ) and field.values[0].is_a?( Hash )
        field.values[0][:type]
      elsif field.is_a?( Hash ) and !field.values[0].is_a?( Hash )
        field.values[0]
      else
        nil
      end
      field = field.is_a?(Hash) ? field.keys[0] : field

      case type
      when :date
        class_eval %Q!
        def #{field}_for_solr
          value = self.send(:#{field})
          value = value.utc.strftime("%Y-%m-%dT%H:%M:%SZ") if value
          value
        end!
      else
        class_eval %Q{
        def #{field}_for_solr
          value = self.send(:#{field}).to_s
          value.gsub!( /[\x00-\x1F]|\x7F/ , ' ')
          value
        end}
      end
    end
    
    def process_fields(raw_field)
      if raw_field.respond_to?(:each)
        raw_field.each do |field|
          next if acts_as_solr_configuration[:exclude_fields].include?(field)
          if field.is_a?( Hash )
            field.each do |k,v|
              get_field_value( k => v )
            end
          else
            get_field_value field
          end
        end                
      end
    end
    
  end
end
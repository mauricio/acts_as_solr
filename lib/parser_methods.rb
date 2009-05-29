module ActsAsSolr #:nodoc:
  
  module ParserMethods
    
    protected    
    
    # Method used by mostly all the ClassMethods when doing a search
    def parse_query(query=nil, options={}, models=nil)
      valid_options = [:offset, :limit, :facets, :models, :results_format, :order, :scores, :operator, :page, :per_page, :conditions, :find]

      if options[:page] and options[:per_page]
        options[:limit] = options[:per_page].to_i
        options[:offset] = (options[:page].to_i - 1 ) * options[:limit]
      end

      if options[:limit] and options[:offset].nil?
        options[:limit] = options[:per_page] = 15
      end

      query_options = {}
      return if query.nil?
      raise "Invalid parameters: #{(options.keys - valid_options).join(',')}" unless (options.keys - valid_options).empty?

      Deprecation.validate_query(options)
      query_options[:start] = options[:offset]
      query_options[:rows] = options[:limit]
      query_options[:operator] = options[:operator]

      # first steps on the facet parameter processing
      if options[:facets]
        query_options[:facets] = {}
        query_options[:facets][:limit] = -1  # TODO: make this configurable
        query_options[:facets][:sort] = :count if options[:facets][:sort]
        query_options[:facets][:mincount] = 0
        query_options[:facets][:mincount] = 1 if options[:facets][:zeros] == false
        query_options[:facets][:fields] = options[:facets][:fields].collect{|k| "#{k}_facet"} if options[:facets][:fields]
        query_options[:filter_queries] = replace_types(options[:facets][:browse].collect{|k| "#{k.sub!(/ *: */,"_facet:")}"}) if options[:facets][:browse]
        query_options[:facets][:queries] = replace_types(options[:facets][:query].collect{|k| "#{k.sub!(/ *: */,"_t:")}"}) if options[:facets][:query]
      end
        
      if models.nil?
        # TODO: use a filter query for type, allowing Solr to cache it individually
        models = "AND #{solr_configuration[:type_field]}:#{self.name}"
        field_list = solr_configuration[:primary_key_field]
      else
        field_list = "id"
      end
        
      query_options[:field_list] = [field_list, 'score']
      query = "(#{query.gsub(/ *: */,"_t:")}) #{models}"
      order = options[:order].split(/\s*,\s*/).collect{|e| e.gsub(/\s+/,'_t ').gsub(/\bscore_t\b/, 'score')  }.join(',') if options[:order]
      query_options[:query] = replace_types([query])[0] # TODO adjust replace_types to work with String or Array

      if options[:order]
        # TODO: set the sort parameter instead of the old ;order. style.
        query_options[:query] << ';' << replace_types([order], false)[0]
      end
               
      ActsAsSolr::Post.execute(Solr::Request::Standard.new(query_options))
    end
    
    # Parses the data returned from Solr
    def parse_results(solr_data, options = {})
      results = {
        :docs => [],
        :total => 0
      }

      if options[:page] and options[:per_page]
        results[:page] = options[:page].to_i
        results[:per_page] = options[:per_page].to_i
      elsif options[:offset] and options[:limit]
        results[:page] = options[:offset].to_i / options[:limit].to_i
        results[:per_page] = options[:limit].to_i
      end

      parse_configuration = {
        :format => :objects
      }
      results.update(:facets => {'facet_fields' => []}) if options[:facets]
      return SearchResults.new(results) if solr_data.total == 0
      
      parse_configuration.update(options) if options.is_a?(Hash)

      ids = solr_data.docs.collect {|doc| doc["#{solr_configuration[:primary_key_field]}"]}.flatten
      conditions = nil
      if options[:conditions].blank?
        conditions = [ "#{quoted_table_name}.#{primary_key} in (?)", ids ]
      else
        conditions = [ "#{quoted_table_name}.#{primary_key} IN (?) AND #{sanitize_sql(options[:conditions])}", ids ]
      end

      query_results = if options[:find]
        with_scope :find => options[:find] do
          find(:all, :conditions => conditions)
        end
      else
        find(:all, :conditions => conditions)
      end

      add_scores(query_results, solr_data) if parse_configuration[:format] == :objects

      result = parse_configuration[:format] == :objects ? reorder( query_results, solr_data, options ) : ids
      
      results.update(:facets => solr_data.data['facet_counts']) if options[:facets]
      results.update({:docs => result, :total => solr_data.total, :max_score => solr_data.max_score})
      results[ :total_pages ] = if results[:per_page]
        solr_data.total / results[:per_page]
      else
        1
      end
      SearchResults.new(results)
    end
    
    # Reorders the instances keeping the order returned from Solr
    def reorder(results, solr_data, options = {})
      return results if options[:find] && options[:find][:order]
      returned_results = []
      solr_data.docs.each_with_index do |doc, index|
        doc_id = doc["#{solr_configuration[:primary_key_field]}"]
        returned_results[index] = results.detect { |i| i.id == doc_id }
      end
      returned_results
    end

    # Replaces the field types based on the types (if any) specified
    # on the acts_as_solr call
    def replace_types(strings, include_colon=true)
      suffix = include_colon ? ":" : ""
      if acts_as_solr_configuration[:solr_fields] && acts_as_solr_configuration[:solr_fields].is_a?(Array)
        acts_as_solr_configuration[:solr_fields].each do |solr_field|
          field_type = get_solr_field_type(:text)
          if solr_field.is_a?(Hash)
            solr_field.each do |name,value|
         	    if value.respond_to?(:each_pair)
                field_type = get_solr_field_type(value[:type]) if value[:type]
              else
                field_type = get_solr_field_type(value)
              end
              field = "#{name.to_s}_#{field_type}#{suffix}"
              strings.each_with_index {|s,i| strings[i] = s.gsub(/#{name.to_s}_t#{suffix}/,field) }
            end
          end
        end
      end
      strings
    end
    
    # Adds the score to each one of the instances found
    def add_scores(results, solr_data)
      results = results.dup
      solr_data.docs.each do |doc|
        item = results.detect { |i| i.id == doc["#{solr_configuration[:primary_key_field]}"] }
        item.solr_score = doc['score']
        results.delete( item )
      end
    end
  end

end
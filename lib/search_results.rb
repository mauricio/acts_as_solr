module ActsAsSolr #:nodoc:
  
  # TODO: Possibly looking into hooking it up with Solr::Response::Standard
  # 
  # Class that returns the search results with four methods.
  # 
  #   books = Book.find_by_solr 'ruby'
  # 
  # the above will return a SearchResults class with 4 methods:
  # 
  # docs|results|records: will return an array of records found
  # 
  #   books.records.empty?
  #   => false
  # 
  # total|num_found|total_hits: will return the total number of records found
  # 
  #   books.total
  #   => 2
  # 
  # facets: will return the facets when doing a faceted search
  # 
  # max_score|highest_score: returns the highest score found
  # 
  #   books.max_score
  #   => 1.3213213
  # 
  # 
  class SearchResults

    include Enumerable
    attr_accessor :total_pages
    attr_accessor :current_page

    def initialize(solr_data={})
      @solr_data = solr_data
      self.total_pages = if self.per_page.nil? || self.total_entries == 0
        1
      elsif self.total_entries % self.per_page == 0
        self.total_entries / self.per_page
      else
        (self.total_entries / self.per_page) + 1
      end
      self.current_page = @solr_data[:page] || 1
    end

    def each( &block )
      self.results.each( &block )
    end

    # Returns an array with the instances. This method
    def results
      @solr_data[:docs]
    end
    
    # Returns the total records found. This method is
    # also aliased as num_found and total_hits
    def total
      @solr_data[:total]
    end
    
    # Returns the facets when doing a faceted search
    def facets
      @solr_data[:facets]
    end
    
    # Returns the highest score found. This method is
    # also aliased as highest_score
    def max_score
      @solr_data[:max_score]
    end

    def blank?
      self.results.blank?
    end

    def size
      self.results.size
    end

    def offset
      (current_page - 1) * per_page
    end

    def per_page
      @solr_data[:per_page] || self.total_entries
    end

    def total_entries
      @solr_data[:total]
    end

    def previous_page
      if current_page > 1
        current_page - 1
      else
        false
      end
    end

    def solr_data
      @solr_data
    end

    def method_missing(symbol, *args, &block)
      self.results.send(symbol, *args, &block)
    rescue NoMethodError
      raise NoMethodError, "There is no method called #{symbol} at #{self.class.name}"
    end

    def next_page
      if current_page < total_pages
        current_page + 1
      else
        false
      end
    end

  end
  
end
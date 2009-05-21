`acts_as_solr Rails plugin`
======
This plugin adds full text search capabilities and many other nifty features from Apache's [Solr](http://lucene.apache.org/solr/) to any Rails model.
It was based on the first draft by Erik Hatcher.

Current Release
======
The current stable release is v1.0 and was released on 20-05-2009.

Changes
======
Please refer to the CHANGE_LOG

Installation
======

script/plugin install git://github.com/mauricio/acts_as_solr.git

Requirements
=====
* Java Runtime Environment(JRE) 1.5 aka 5.0 or higher [http://java.sun.com/](http://java.sun.com/)

Features
======

* Fully compatible with will_paginate view helpers and :page/:per_page options
* Using Solr 1.3.0

Things to be done
======

* Simplify configuration
* Examples using the "did you mean?" feature
* Upgrade and improve Jetty config

Mantainer
======
Maurício Linhares (mauricio dot linhares AT gmail dot com)

Original Authors
======
* Erik Hatcher
* Thiago Jackiw

Release Information
======
Released under the MIT license.

More info
======
[http://github.com/mauricio/acts_as_solr/tree/master](http://github.com/mauricio/acts_as_solr/tree/master)

Basic Usage
======
<pre><code>
# Just include the line below to any of your ActiveRecord models:

  class Book < ActiveRecord::Base
    acts_as_solr
  end

# With this acts_as_solr will index all string and text fields on your
# active_record model

# Or if you want, you can specify only the fields that should be indexed:

  class Book < ActiveRecord::Base
    acts_as_solr :fields => [:name, :author]
  end

# The "fields" that are going to be indexed don't need to be database fields,
# they can be simple methods on your model:

  class Book < ActiveRecord::Base

    belongs_to :author

    acts_as_solr :fields => [:name, :author_name]

    def author_name
      self.author.name if self.author
    end

  end

# Then to find instances of your model, just do:
  books = Book.find_by_solr(query)

# "query" is a string representing your query
# You can find out more about Lucene's query sintax here:
# http://lucene.apache.org/java/2_4_1/queryparsersyntax.html

# Finding using pagination:

  books = Book.find_by_solr( query, :page => 2, :per_page => 10 )

# The object returned by a find_by_solr call is an ActsAsSolr::SearchResults
# object where you can find out more about the response Solr sent back to you and
# the real active_record objects returned by your query.

# This object works just like any other Enumerable (as an Array) and you can
# call any Enumerable method on it. It's also completely compatible with 
# will_paginate view helpers.

  books = Book.find_by_solr( query, :page => 2, :per_page => 10 )
  books.each do |book| # this "book" variable is a real Book object from the database
    puts "#{book.name} - #{book.author_name} - #{book.year}"
  end

# Please see ActsAsSolr::ActsMethods for a complete info

</code></pre>
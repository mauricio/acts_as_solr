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

* Examples using the "did you mean?" feature

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

Migrating from older versions
======

If you're migrating from older acts_as_solr versions (that probably came from
another repo and not http://github.com/mauricio/acts_as_solr/tree/master )
all you have to do is to copy the "jetty/solr/conf" folder to your "RAILS_ROOT/config/solr".
Config files now live in your application and not the plugin.

More info
======
[http://wiki.github.com/mauricio/acts_as_solr](http://wiki.github.com/mauricio/acts_as_solr)

Basic Usage
======
<pre><code>
# Just include the line below to any of your ActiveRecord models:

  class Book < ActiveRecord::Base
    acts_as_solr
  end

# With this acts_as_solr will index all fields in your active_record model
# that are not it's primary key, crated_at or updated_at fields.

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

# And this is all there is to it, you don't need to get your hands dirty on
# Solr schema or document files, only if the default config doesn't suit your
# needs. After every save/destroy the Solr index for that object is going to be
# updated, so all you need to do is configure your active_record object as above
# start the Solr server (rake solr:start) and be done with it.

# If you're starting up from an already populated database, you'll have to build
# and index based on that data. To do this, start the Solr server (rake solr:start)
# and then call the reindex task (rake solr:rebuild_index), this will rebuild
# the index based on all objects currently stored on your database.

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
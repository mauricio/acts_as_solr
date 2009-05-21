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

Requirements
------
* Java Runtime Environment(JRE) 1.5 aka 5.0 or higher [http://java.sun.com/](http://java.sun.com/)

Basic Usage
======
<pre><code>
# Just include the line below to any of your ActiveRecord models:
  acts_as_solr

# Or if you want, you can specify only the fields that should be indexed:
  acts_as_solr :fields => [:name, :author]

# Then to find instances of your model, just do:
  Model.find_by_solr(query) #query is a string representing your query
                            #you can find out more about Lucene's query sintax here:
                            #http://lucene.apache.org/java/2_4_1/queryparsersyntax.html

# Finding using pagination:

  Model.find_by_solr( query, :page => 2, :per_page => 10 )

# Please see ActsAsSolr::ActsMethods for a complete info

</code></pre>

Features
=====

* Fully compatible with will_paginate view helpers and :page/:per_page options
* Using Solr 1.3.0

Things to be done
=====

* Simplify configuration
* Examples using the "did you mean?" feature
* Upgrade and improve Jetty config

Mantainer
=====
Maurício Linhares (mauricio dot linhares AT gmail dot com)

Original Authors
=====
Erik Hatcher
Thiago Jackiw

Release Information
=====
Released under the MIT license.

More info
=====
[http://github.com/mauricio/acts_as_solr/tree/master](http://github.com/mauricio/acts_as_solr/tree/master)
#!/usr/bin/ruby -rrubygems
require 'dm-migrations'
require 'dm-validations'
require 'film_domain'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/miff_2010.db")
DataMapper::setup(:freebase_repo, :adapter => 'freebase')

DataMapper.auto_upgrade!

#!/usr/bin/env ruby

require 'treequel'

dir = Treequel.directory( :host => 'localhost', :basedn => 'dc=laika,dc=com' )

people = dir.ou( :People )

last_name_f_people = people.filter( :lastName => 'f*' )
# =>

last_name_f_people.all
# => 

appperms = dir.ou( :AppPerms )
appperms.scope( :subtree ).filter( :or => [[:cn, 'facet'], [:cn, 'structure'], [:cn, 'envision']] )
appperms.scope( :subtree ).filter( :| => [[:cn, 'facet'], [:cn, 'structure'], [:cn, 'envision']] )

appperms.scope( :subtree ).filter( :or => [:cn, 'facet']).filter( :or => [:cn, 'structure'] )


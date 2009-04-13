#!/usr/bin/env ruby

require 'treequel'

dir = Treequel.directory( :host => 'localhost', :basedn => 'dc=laika,dc=com' )

people = dir.ou( :People )

last_name_f_people = people.filter( :lastName => 'f*' )
# =>

last_name_f_people.all
# => 

appperms.filter( :cn = 'plorp ')

appperms = dir.ou( :AppPerms )
appperms.filter( [:or, 'cn~=facet', 'cn=structure', 'cn=envision'] )
appperms.filter( [:| => [:cn, 'facet'], [ :cn, 'structure' ], [:cn, 'envision']] )



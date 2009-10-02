#!/usr/bin/env ruby

# A spike to work out the details of the controls interface to Branches

require 'treequel'

dir = Treequel.directory( :host => 'localhost', :basedn => 'dc=acme,dc=com' )
dir.register_control( )

people = dir.ou( :People )

sorted_people = people.control( )
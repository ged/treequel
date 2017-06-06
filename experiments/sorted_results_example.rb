#!/usr/bin/env ruby -w
#
# Program to demonstrate the use of the LDAPv3 PagedResults control. This
# control is interesting, because it requires the passing of controls in
# both directions between the client and the server.

require 'rubygems'
require 'treequel'
require 'treequel/controls/sortedresults'

dir = Treequel.directory
dir.register_controls( Treequel::SortedResultsControl )

people = dir.ou( :people ).filter( :objectClass => 'person' ).order( :sn, :givenName ).limit( 5 )

puts people.collect {|person| "%s, %s" % person.values_at(:sn, :givenName) }
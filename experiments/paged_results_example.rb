#!/usr/bin/env ruby -w
#
# Program to demonstrate the use of the LDAPv3 PagedResults control. This
# control is interesting, because it requires the passing of controls in
# both directions between the client and the server.

require 'rubygems'
require 'treequel'
require 'treequel/controls/pagedresults'

unless ARGV[0]
	$stderr.puts "Please give a page size."
	exit
end
page_size = ARGV[0].to_i

dir = Treequel.directory
dir.register_controls( Treequel::PagedResultsControl )

#Treequel.logger.level = Logger::DEBUG
people = dir.ou( :people ).filter( :objectClass => 'person' ).with_paged_results( page_size )

count = page = 0
begin
	records = people.all
	count += records.length
	page += 1

	$stderr.puts "Page %d has %d entries." % [ page, records.length ],
		"That's %d entries in total." % [ count ]
	$stderr.puts "Cookie is: 0x%s" % [ people.paged_results_cookie.unpack('H*').first ]
end while people.has_more_results?


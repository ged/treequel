#!/usr/bin/env ruby
# coding: utf-8

require 'ldap'

require 'treequel'
require 'treequel/control'


# A Treequel::Control module that implements the "LDAP Control Extension
# for Simple Paged Results Manipulation" (RFC 2696).
# 
# == Usage
# 
# As with all Controls, you must first register the control with the
# Treequel::Directory object you're intending to search:
#   
#   dir = Treequel.directory( 'ldap://ldap.acme.com/dc=acme,dc=com' )
#   dir.register_controls( Treequel::PagedResultsControl )
# 
# Once that's done, any Treequel::Branchset you create will have the
# #with_paged_results method that will allow you to specify the number
# of results you wish to be returned per "page":
# 
#   # Fetch people in pages
#   people = dir.ou( :People )
#   paged_people = people.filter( :objectClass => :person ).with_paged_results( 25 )
# 
# The Branchset will also respond to #has_more_results?, which will
# be true while there are additional pages to be fetched, or before
# the search has taken place:
# 
#   # Display each set of 25, waiting for keypress between each set
#   while paged_people.has_more_results?
#       # do something with this set of 25 people...
#   end
#   
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
# 
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel::PagedResultsControl
	include Treequel::Control

	# The control's OID
	OID = '1.2.840.113556.1.4.319'

	# The default number of results per page
	DEFAULT_PAGE_SIZE = 100


	### Extension callback -- add the requisite instance variables to including Branchsets.
	def self::extend_object( branchset )
		super
		branchset.instance_variable_set( :@paged_results_cookie, nil )
		branchset.instance_variable_set( :@paged_results_setsize, DEFAULT_PAGE_SIZE )
	end


	######
	public
	######

	# The number of results per page
	attr_accessor :paged_results_setsize

	# The (opaque) cookie value that will be sent to the server on the next search.
	attr_reader :paged_results_cookie


	### Clone the Branchset with a paged results control added and return it.
	def with_paged_results( setsize )
		self.log.warn "This control will likely not work in ruby-ldap versions " +
			" <= 0.9.9. See http://code.google.com/p/ruby-activeldap/issues/" +
			"detail?id=38 for details." if LDAP::PATCH_VERSION < 10

		newset = self.clone
		newset.paged_results_setsize = setsize

		return newset
	end


	### Returns +true+ if the first page of results has been fetched and there are
	### more pages remaining.
	def has_more_results?
		return true unless self.paged_results_cookie == ''
	end


	### Override the Enumerable method to update the cookie value each time a page 
	### is fetched.
	def each( &block )
		super do |branch|
			if paged_control = branch.controls.find {|control| control.oid == OID }
				returned_size, cookie = paged_control.decode
				self.log.debug "Paged control in result with size = %p, cookie = %p" %
					[ returned_size, cookie ]
				@paged_results_cookie = cookie
			else
				self.log.debug "No paged control in results. Setting cookie to ''."
				@paged_results_cookie = ''
			end

			block.call( branch )
		end
	end


	#########
	protected
	#########

	### Treequel::Control API -- Get a configured LDAP::Control object for this
	### Branchset.
	def get_server_controls
		controls = super
		value = LDAP::Control.encode( @paged_results_setsize.to_i, @paged_results_cookie.to_s )
		return controls << LDAP::Control.new( OID, value, true )
	end

end

# -*- ruby -*-
#encoding: utf-8
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
module Treequel::PagedResultsControl
	include Treequel::Control

	# The control's OID
	OID = '1.2.840.113556.1.4.319'

	# The default number of results per page
	DEFAULT_PAGE_SIZE = 100


	### Add the control's instance variables to including Branchsets.
	def initialize
		@paged_results_cookie = nil
		@paged_results_setsize = nil
	end


	######
	public
	######

	# The number of results per page
	attr_accessor :paged_results_setsize

	# The (opaque) cookie value that will be sent to the server on the next search.
	attr_accessor :paged_results_cookie


	### Clone the Branchset with a paged results control with paging set to +setsize+.
	def with_paged_results( setsize=DEFAULT_PAGE_SIZE )
		self.log.warn "This control will likely not work in ruby-ldap versions " +
			" <= 0.9.9. See http://code.google.com/p/ruby-activeldap/issues/" +
			"detail?id=38 for details." if LDAP::PATCH_VERSION < 10

		newset = self.clone

		if setsize.nil? || setsize.zero?
			self.log.debug "Removing paged results control."
			newset.paged_results_setsize = nil
		else
			self.log.debug "Adding paged results control with page size = %d." % [ setsize ]
			newset.paged_results_setsize = setsize
		end

		return newset
	end


	### Clone the Branchset without paging and return it.
	def without_paging
		copy = self.clone
		copy.without_paging!
		return copy
	end


	### Remove any paging control associated with the receiving Branchset.
	def without_paging!
		self.paged_results_cookie = nil
		self.paged_results_setsize = nil
	end


	### Returns +true+ if the first page of results has been fetched and there are
	### more pages remaining.
	def has_more_results?
		return true unless self.done_paging?
	end


	### Returns +true+ if results have yet to be fetched, or if they have all been
	### fetched.
	def done_paging?
		return self.paged_results_cookie == ''
	end


	### Override the Enumerable method to update the cookie value each time a page
	### is fetched.
	def each( &block )
		super do |branch|
			if paged_control = branch.controls.find {|control| control.oid == OID }
				returned_size, cookie = paged_control.decode
				self.log.debug "Paged control in result with size = %p, cookie = %p" %
					[ returned_size, cookie ]
				self.paged_results_cookie = cookie
			else
				self.log.debug "No paged control in results. Setting cookie to ''."
				self.paged_results_cookie = ''
			end

			block.call( branch )
		end
	end


	#########
	protected
	#########

	### Treequel::Control API -- Get the set of server controls currently configured for
	### the receiver.
	def get_server_controls
		controls = super
		if pagesize = self.paged_results_setsize && self.paged_results_setsize.nonzero?
			self.log.debug "Setting up paging for sets of %d" % [ pagesize ]
			value = LDAP::Control.encode( pagesize.to_i, self.paged_results_cookie.to_s )
			controls << LDAP::Control.new( OID, value, true )
		else
			self.log.debug "No paging for this %p; not adding the PagedResults control" %
				[ self.class ]
		end

		return controls
	end

end # module Treequel::PagedResultsControl


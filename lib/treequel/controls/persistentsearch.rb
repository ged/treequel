#!/usr/bin/env ruby
# coding: utf-8

require 'ldap'

require 'treequel'
require 'treequel/control'


# A Treequel::Control module that implements the "Persistent Search"
# control (http://tools.ietf.org/html/draft-smith-psearch-ldap-01)
# 
# == Usage
# 
# As with all Controls, you must first register the control with the
# Treequel::Directory object you're intending to search:
#   
#   dir = Treequel.directory( 'ldap://ldap.acme.com/dc=acme,dc=com' )
#   dir.register_controls( Treequel::PersistentSearchControl )
# 
# Once that's done, any Treequel::Branchset you create will have the
# #on_changes method that allows you to set a callback for changes
# that happen to the search results:
# 
#   # Build DHCP records out of all the hosts in the directory, then rebuild
#   # everything when a host record changes.
#   hosts = dir.filter( :ou => Hosts ).collection
#   hosts.filter( :objectClass => :ipHost ).on_changes do |
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel::PersistentSearchControl
	include Treequel::Control

	# The control's OID
	OID = '2.16.840.1.113730.3.4.3'


	### Extension callback -- add the requisite instance variables to including Branchsets.
	def self::extend_object( branchset )
		super
		branchset.instance_variable_set( :@persistent_search_callback, nil )
	end


	######
	public
	######

	# The callback to call when results change
	attr_accessor :paged_results_setsize


	### Clone the Branchset with a persistent change callback.
	def with_paged_results( setsize )
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

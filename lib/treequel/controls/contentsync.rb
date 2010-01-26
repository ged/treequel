#!/usr/bin/env ruby
# coding: utf-8

require 'ldap'
require 'openssl'

require 'treequel'
require 'treequel/control'
require 'treequel/constants'


# A Treequel::Control module that implements the "Content Sync"
# control (RFC 4533)
# 
# == Usage
# 
# As with all Controls, you must first register the control with the
# Treequel::Directory object you're intending to search:
#   
#   dir = Treequel.directory( 'ldap://ldap.acme.com/dc=acme,dc=com' )
#   dir.register_controls( Treequel::ContentSyncControl )
# 
# Once that's done, any Treequel::Branchset you create will have the #on_sync
# method:
# 
#   # Build DHCP records out of all the hosts in the directory, then rebuild
#   # everything when a host record changes.
#   hosts = dir.filter( :ou => Hosts ).collection
#   hosts.filter( :objectClass => :ipHost ).on_sync do ||
#       # 
#   end
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
module Treequel::ContentSyncControl
	include Treequel::Control,
	        Treequel::Constants

	# The control's OID
	OID = CONTROL_OIDS[:sync]

	# Sync mode constants (from RFC4533, section 2.2)
	SYNC_MODE_REFRESH = 1
	SYNC_MODE_REFRESH_AND_PERSIST = 3

	### Extension callback -- add the requisite instance variables to including Branchsets.
	def self::extend_object( branchset )
		super
		branchset.instance_variable_set( :@content_sync_callback, nil )
	end


	######
	public
	######

	# The callback to call when results change
	attr_accessor :content_sync_callback


	### Clone the Branchset with a persistent change callback.
	def on_sync( &callback )
		newset = self.clone
		newset.content_sync_callback = callback

		return newset
	end


	### Override the Enumerable method to update the cookie value each time a page 
	### is fetched.
	def each( &block )
		super do |branch|
			self.log.debug "Looking for the sync control in controls: %p" % [ branch.controls ]
			branch.controls.each do |control|
				self.log.debug "  got a %s control: %p" % [
					CONTROL_NAMES[control.oid],
					control.decode,
				]

				case control.oid
				when CONTROL_OIDS[:sync_state]
					self.log.debug "  got a 'state' control"
					block.call( branch )
				when CONTROL_OIDS[:sync_done]
					self.log.debug "  got a 'done' control"
					break
				else
					self.log.info "  got an unexpected control (%p)" % [ control ]
				end
			end
		end
	end


	#########
	protected
	#########

	### Make the ASN.1 string for the control value out of the given +mode+, 
	### +cookie+, +reload_hint+.
	def make_sync_control_value( mode, cookie, reload_hint )
		# (http://tools.ietf.org/html/rfc4533#section-2.2):
		# syncRequestValue ::= SEQUENCE {
		#     mode ENUMERATED {
		#         -- 0 unused
		#         refreshOnly       (1),
		#         -- 2 reserved
		#         refreshAndPersist (3)
		#     },
		#     cookie     syncCookie OPTIONAL,
		#     reloadHint BOOLEAN DEFAULT FALSE
		# }
		encoded_vals = [
			OpenSSL::ASN1::Enumerated.new( SYNC_MODE_REFRESH_AND_PERSIST )
		]
		return OpenSSL::ASN1::Sequence.new( encoded_vals ).to_der
	end


	### Treequel::Control API -- Get a configured LDAP::Control object for this
	### Branchset.
	def get_server_controls
		controls = super
		value = self.make_sync_control_value( 1, '', false )
		return controls << LDAP::Control.new( OID, value, true )
	end

end

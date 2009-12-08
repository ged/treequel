#!/usr/bin/env ruby

# A spike to work out the details of the controls interface to Branches

require 'treequel/control'

module Treequel::PagedResultsControl
	include Treequel::Control

	OID = '1.2.840.113556.1.4.319'

	def initialize( *unused )
		super
		@paged_results_cookie = nil
		@paged_results_setsize = 100
	end


	attr_accessor :paged_results_setsize

	def with_paged_results( setsize )
		newset = self.clone
		newset.paged_results_setsize = setsize

		return newset
	end

	def has_more_results?
		return true unless @paged_results_cookie == ''
	end

	#########
	protected
	#########

	def get_server_controls
		controls = super
		return controls <<
			LDAP::Control.new( OID, [@paged_results_setsize, @paged_results_cookie], true )
	end

end


module Treequel::PersistentSearchControl
	include Treequel::Control

	OID = '2.16.840.1.113730.3.4.3'

	def initialize( *args )
		super
		@change_types = 0
		@changes_only = true
		@return_ecs   = true
		@callback     = Proc.new {}
	end


	def with_persistent_search( change_types, changes_only=true, return_ecs=true, &callback )
		raise LocalJumpError, "no block given" unless callback
		newset = self.clone
		newset.change_types = change_types
		newset.changes_only = changes_only
		newset.return_ecs   = return_ecs
		newset.callback     = callback

		return newset
	end

	#########
	protected
	#########

	def get_server_controls
		controls = super
		values = [
			@change_types,
			@changes_only ? 1 : 0,
			@return_ecs ? 1 : 0
		]
		return controls << LDAP::Control.new( OID, values, true )
	end

end

dir = Treequel.directory( :host => 'localhost', :basedn => 'dc=acme,dc=com' )
dir.register_control( Treequel::PagedResultsControl, Treequel::PersistentSearchControl )


### Paged results control

# Fetch people in pages
people = dir.ou( :People )
paged_people = people.filter( :objectClass => :person ).with_paged_results( 25 )

# Display each set of 25, waiting for keypress between each set
while paged_people.has_more_results?
	display_people( paged_people.all )
	wait_for_keypress()
end


### Persistent search control
hosts = dir.filter( :objectClass => :laikaHost )
hosts.with_persistent_search( :all ) do |msg, entry, ctrl|
	# do something interesting on update...
end

hosts.all


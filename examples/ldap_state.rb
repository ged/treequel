#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

# Use the OpenLDAP monitoring interface (cn=Monitor) to poll a collection of LDAP
# servers for collection information. See 
# 
#   http://www.openldap.org/doc/admin24/monitoringslapd.html 
# 
# for details on how to set your servers up with this interface.
# 
# Original ruby-ldap version by Mahlon E. Smith.
# Ported to Treequel by Michael Granger

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'rubygems'
require 'treequel'

BIND_DN = 'cn=admin,cn=Monitor'
BIND_PASS = 'XXX'

SERVER_LIST = %w{
	ldap1.acme.com
	ldap2.acme.com
	ldap3.acme.com
}

Treequel::Branch.include_operational_attrs = true

total_connections = 0
total_operations  = 0

SERVER_LIST.each do |server|
	con = ops = 0
	dir = Treequel.directory( :host => server, :base_dn => 'cn=Monitor' )

	conns = dir.cn( :connections ).filter( :objectClass => :monitorConnection ).
	select( :monitorConnectionNumber, :monitorConnectionOpsExecuting )

	dir.bound_as( BIND_DN, BIND_PASS ) do
		con = conns.all.length
		ops = conns.map( :monitorConnectionOpsExecuting ).
			collect {|connops| connops.first.to_i }.
			inject  {|sum,connops| sum + connops }

		puts "LDAP server: %s\n\t%s\n\tServing %d operations across %d clients\n\n" % [
			server, dir[:monitoredInfo], ops, con
		]
	end

	total_connections = total_connections + con
	total_operations  = total_operations  + ops
end

puts "\n%d active operations across %d clients\n" % [ total_operations, total_connections ]


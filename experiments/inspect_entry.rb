#!/usr/bin/env ruby

# An experiment to see if LDAP::Entry objects can be inspected outside of IRb

require 'ldap'
require 'pathname'

require Pathname( __FILE__ ).dirname + 'utils.rb'
include UtilityFunctions

c = LDAP::SSLConn.new( 'ldap.laika.com', 389, true )
a = []
c.search( 'ou=People,dc=laika,dc=com', LDAP::LDAP_SCOPE_SUBTREE, 'uid=mahlon' ) do |entry|
	puts entry.inspect
	a << entry
end

puts a.first.inspect




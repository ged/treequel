#!/usr/bin/ruby

require 'ldap'
require 'treequel'


module Treequel::Constants # :nodoc:

	SCOPE = {
		:onelevel => LDAP::LDAP_SCOPE_ONELEVEL,
		:base     => LDAP::LDAP_SCOPE_BASE,
		:subtree  => LDAP::LDAP_SCOPE_SUBTREE,
	}.freeze
	

end # module Treequel

# vim: set nosta noet ts=4 sw=4:



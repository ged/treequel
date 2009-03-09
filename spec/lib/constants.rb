#!/usr/bin/env ruby

require 'ldap'
require 'treequel'


### A collection of constants used in testing
module Treequel::TestConstants # :nodoc:all
	
	unless defined?( TEST_HOST )
		
		TEST_HOST      = 'ldap.example.com'
		TEST_PORT      = LDAP::LDAP_PORT
		TEST_BASE_DN   = 'o=Acme'
		
		TEST_BIND_DN   = "cn=admin,#{TEST_BASE_DN}"
		TEST_BIND_PASS = 'passomaquoddy'
		

		constants.each do |cname|
			const_get(cname).freeze
		end
	end
	
end



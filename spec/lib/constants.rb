#!/usr/bin/env ruby

require 'ldap'
require 'treequel'


### A collection of constants used in testing
module Treequel::TestConstants # :nodoc:all

	unless defined?( TEST_HOST )

		TEST_HOST            = 'ldap.example.com'
		TEST_PORT            = LDAP::LDAP_PORT
		TEST_BASE_DN         = 'dc=acme,dc=com'

		TEST_BIND_DN         = "cn=admin,#{TEST_BASE_DN}"
		TEST_BIND_PASS       = 'passomaquoddy'

		TEST_HOSTS_DN_ATTR   = 'ou'
		TEST_HOSTS_DN_VALUE  = 'Hosts'
		TEST_HOSTS_RDN       = "#{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE}"
		TEST_HOSTS_DN        = "#{TEST_HOSTS_RDN},#{TEST_BASE_DN}"

		TEST_PEOPLE_DN_ATTR  = 'ou'
		TEST_PEOPLE_DN_VALUE = 'People'
		TEST_PEOPLE_RDN      = "#{TEST_PEOPLE_DN_ATTR}=#{TEST_PEOPLE_DN_VALUE}"
		TEST_PEOPLE_DN       = "#{TEST_PEOPLE_RDN},#{TEST_BASE_DN}"

		TEST_PERSON_DN_ATTR  = 'uid'
		TEST_PERSON_DN_VALUE = 'arogers'
		TEST_PERSON_RDN      = "#{TEST_PERSON_DN_ATTR}=#{TEST_PERSON_DN_VALUE}"
		TEST_PERSON_DN       = "#{TEST_PERSON_RDN},#{TEST_PEOPLE_DN}"

		constants.each do |cname|
			const_get(cname).freeze
		end
	end

end



#!/usr/bin/env ruby

require 'yaml'
require 'ldap'
require 'treequel'


### A collection of constants used in testing
module Treequel::SpecConstants # :nodoc:all

	include Treequel::Constants,
	        Treequel::Constants::OIDS

	unless defined?( TEST_HOST )

		TEST_HOST             = 'ldap.example.com'
		TEST_PORT             = LDAP::LDAP_PORT
		TEST_BASE_DN          = 'dc=acme,dc=com'
		TEST_LDAPURI          = "ldap://#{TEST_HOST}:#{TEST_PORT}/#{TEST_BASE_DN}"

		TEST_BIND_DN          = "cn=admin,#{TEST_BASE_DN}"
		TEST_BIND_PASS        = 'passomaquoddy'

		TEST_DSE = [{
			"supportedSASLMechanisms" => [
				"SRP", "SRP", "SRP", "PLAIN", "PLAIN",
				"PLAIN", "OTP", "OTP", "OTP", "NTLM", "NTLM", "NTLM", "LOGIN",
				"LOGIN", "LOGIN", "GSSAPI", "GSSAPI", "GSSAPI", "DIGEST-MD5",
				"DIGEST-MD5", "DIGEST-MD5", "CRAM-MD5", "CRAM-MD5", "CRAM-MD5"
			],
			"supportedFeatures" => [
				"1.3.6.1.1.14", "1.3.6.1.4.1.4203.1.5.1", "1.3.6.1.4.1.4203.1.5.2",
				"1.3.6.1.4.1.4203.1.5.3", "1.3.6.1.4.1.4203.1.5.4",
				"1.3.6.1.4.1.4203.1.5.5"
			],
			"namingContexts" => [TEST_BASE_DN],
			"supportedLDAPVersion" => ["3"],
			"subschemaSubentry" => ["cn=Subschema"],
			"supportedControl" => [
				"1.3.6.1.4.1.4203.1.9.1.1", "2.16.840.1.113730.3.4.18",
				"2.16.840.1.113730.3.4.2", "1.3.6.1.4.1.4203.1.10.1",
				"1.2.840.113556.1.4.319", "1.2.826.0.1.334810.2.3",
				"1.2.826.0.1.3344810.2.3", "1.3.6.1.1.13.2",
				"1.3.6.1.1.13.1", "1.3.6.1.1.12",
				"1.2.840.113556.1.4.473", "1.2.840.113556.1.4.474"
			],
			"supportedExtension" => [
				"1.3.6.1.4.1.1466.20037", "1.3.6.1.4.1.4203.1.11.1",
				"1.3.6.1.4.1.4203.1.11.3"
			],
			"dn"=>[""]
		}]
		TEST_DSE.first.keys.each {|key| TEST_DSE.first[key].freeze }

		SCHEMA_DUMPFILE = Pathname( __FILE__ ).dirname + 'data' + 'schema.yml'
		SCHEMAHASH      = LDAP::Schema.new( YAML.load_file(SCHEMA_DUMPFILE) )
		SCHEMA          = Treequel::Schema.new( SCHEMAHASH )

		TEST_HOSTS_DN_ATTR      = 'ou'
		TEST_HOSTS_DN_VALUE     = 'Hosts'
		TEST_HOSTS_RDN          = "#{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE}"
		TEST_HOSTS_DN           = "#{TEST_HOSTS_RDN},#{TEST_BASE_DN}"

		TEST_HOST_DN_ATTR       = 'cn'
		TEST_HOST_DN_VALUE      = 'splinky'
		TEST_HOST_RDN           = "#{TEST_HOST_DN_ATTR}=#{TEST_HOST_DN_VALUE}"
		TEST_HOST_DN            = "#{TEST_HOST_RDN},#{TEST_HOSTS_DN}"

		TEST_SUBDOMAIN_DN_ATTR  = 'dc'
		TEST_SUBDOMAIN_DN_VALUE = 'corp'
		TEST_SUBDOMAIN_RDN      = "#{TEST_SUBDOMAIN_DN_ATTR}=#{TEST_SUBDOMAIN_DN_VALUE}"
		TEST_SUBDOMAIN_DN       = "#{TEST_SUBDOMAIN_RDN},#{TEST_BASE_DN}"

		TEST_SUBHOSTS_DN_ATTR   = 'ou'
		TEST_SUBHOSTS_DN_VALUE  = 'Hosts'
		TEST_SUBHOSTS_RDN       = "#{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE}"
		TEST_SUBHOSTS_DN        = "#{TEST_HOSTS_RDN},#{TEST_SUBDOMAIN_DN}"

		TEST_SUBHOST_DN_ATTR    = 'cn'
		TEST_SUBHOST_DN_VALUE   = 'ronky'
		TEST_SUBHOST_RDN        = "#{TEST_SUBHOST_DN_ATTR}=#{TEST_SUBHOST_DN_VALUE}"
		TEST_SUBHOST_DN         = "#{TEST_SUBHOST_RDN},#{TEST_SUBHOSTS_DN}"

		TEST_PEOPLE_DN_ATTR     = 'ou'
		TEST_PEOPLE_DN_VALUE    = 'People'
		TEST_PEOPLE_RDN         = "#{TEST_PEOPLE_DN_ATTR}=#{TEST_PEOPLE_DN_VALUE}"
		TEST_PEOPLE_DN          = "#{TEST_PEOPLE_RDN},#{TEST_BASE_DN}"

		TEST_PERSON_DN_ATTR     = 'uid'
		TEST_PERSON_DN_VALUE    = 'slappy'
		TEST_PERSON_RDN         = "#{TEST_PERSON_DN_ATTR}=#{TEST_PERSON_DN_VALUE}"
		TEST_PERSON_DN          = "#{TEST_PERSON_RDN},#{TEST_PEOPLE_DN}"

		TEST_PERSON2_DN_ATTR    = 'uid'
		TEST_PERSON2_DN_VALUE   = 'gmichaels'
		TEST_PERSON2_RDN        = "#{TEST_PERSON2_DN_ATTR}=#{TEST_PERSON2_DN_VALUE}"
		TEST_PERSON2_DN         = "#{TEST_PERSON2_RDN},#{TEST_PEOPLE_DN}"

		TEST_PHONES_DN_ATTR     = 'ou'
		TEST_PHONES_DN_VALUE    = 'Phones'
		TEST_PHONES_RDN         = "#{TEST_PHONES_DN_ATTR}=#{TEST_PHONES_DN_VALUE}"
		TEST_PHONES_DN          = "#{TEST_PHONES_RDN},#{TEST_BASE_DN}"

		TEST_ROOMS_DN_ATTR      = 'ou'
		TEST_ROOMS_DN_VALUE     = 'Rooms'
		TEST_ROOMS_RDN          = "#{TEST_ROOMS_DN_ATTR}=#{TEST_ROOMS_DN_VALUE}"
		TEST_ROOMS_DN           = "#{TEST_ROOMS_RDN},#{TEST_BASE_DN}"

		TEST_ROOM_DN_ATTR       = 'cn'
		TEST_ROOM_DN_VALUE      = 'broomcloset'
		TEST_ROOM_RDN           = "#{TEST_ROOM_DN_ATTR}=#{TEST_ROOM_DN_VALUE}"
		TEST_ROOM_DN            = "#{TEST_ROOM_RDN},#{TEST_ROOMS_DN}"

		# Multivalue DN
		TEST_HOST_MULTIVALUE_DN_ATTR1  = 'cn'
		TEST_HOST_MULTIVALUE_DN_VALUE1 = 'honcho'
		TEST_HOST_MULTIVALUE_DN_ATTR2  = 'l'
		TEST_HOST_MULTIVALUE_DN_VALUE2 = 'sandiego'
		TEST_HOST_MULTIVALUE_RDN       = "%s=%s+%s=%s" % [
			TEST_HOST_MULTIVALUE_DN_ATTR1,
			TEST_HOST_MULTIVALUE_DN_VALUE1,
			TEST_HOST_MULTIVALUE_DN_ATTR2,
			TEST_HOST_MULTIVALUE_DN_VALUE2,
		]
		TEST_HOST_MULTIVALUE_DN        = "#{TEST_HOST_MULTIVALUE_RDN},#{TEST_HOSTS_DN}"

		# Test entry hashes
		TEST_HOSTS_ENTRY = {
			'dn'               => [TEST_HOSTS_DN],
			TEST_HOSTS_DN_ATTR => [TEST_HOSTS_DN_VALUE], 
			'objectClass'      => ['top', 'organizationalUnit'],
			'description'      => ['Hosts under acme.com'],
		}

		TEST_PEOPLE_ENTRY = {
			'dn'               => [TEST_PEOPLE_DN],
			TEST_PEOPLE_DN_ATTR => [TEST_PEOPLE_DN_VALUE], 
			'objectClass'      => ['top', 'organizationalUnit'],
			'description'      => ['Acme.com employees'],
		}

		TEST_PERSON_ENTRY = {
			'dn'                => [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE],
			'cn'                => ['Slappy the Frog'],
			'givenName'         => ['Slappy'],
			'sn'                => ['Frog'],
			'l'                 => ['a forest in England'],
			'title'             => ['Forest Fire Prevention Advocate'],
			'displayName'       => ['Slappy the Frog'],
			'logonTime'         => ['1293167318'],
			'uidNumber'         => ['1121'],
			'gidNumber'         => ['200'],
			'homeDirectory'     => ['/u/j/jrandom'],
			'description'       => [
				'Smokey the Bear is much more intense in person.', 
				'Alright.'
			],
			'objectClass'       => %w[
				top
				person
				organizationalPerson
				inetOrgPerson
				posixAccount
				shadowAccount
				apple-user
			],
		}

		TEST_OPERATIONAL_PEOPLE_ENTRY = TEST_PEOPLE_ENTRY.merge(
			'structuralObjectClass' => ['organizationalUnit'],
			'entryUUID'             => ['5035e674-bae3-102b-992e-e9e937d524d6'],
			'creatorsName'          => ['cn=admin,dc=laika,dc=com'],
			'createTimestamp'       => ['20070629232213Z'],
			'entryCSN'              => ['20070629232213.000000Z#000000#000#000000'],
			'modifiersName'         => ['cn=admin,dc=laika,dc=com'],
			'modifyTimestamp'       => ['20070629232213Z'],
			'entryDN'               => [TEST_PEOPLE_DN],
			'subschemaSubentry'     => ['cn=Subschema'],
			'hasSubordinates'       => ['TRUE']
		)

		TEST_OPERATIONAL_PERSON_ENTRY = TEST_PERSON_ENTRY.merge(
			'structuralObjectClass' => ['inetOrgPerson'],
			'entryUUID'             => ['65acd5dc-b146-102f-8d60-c1597577de09'],
			'creatorsName'          => ['cn=admin,dc=laika,dc=com'],
			'createTimestamp'       => ['20110110204609Z'],
			'entryCSN'              => ['20110224232421.753555Z#000000#000#000000'],
			'modifiersName'         => ['cn=admin,dc=laika,dc=com'],
			'modifyTimestamp'       => ['20110224232421Z'],
			'entryDN'               => [TEST_PEOPLE_DN],
			'subschemaSubentry'     => ['cn=Subschema'],
			'hasSubordinates'       => ['FALSE']
		)


		constants.each do |cname|
			const_get(cname).freeze
		end
	end

end



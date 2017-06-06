#!/usr/bin/env ruby
# coding: utf-8

require 'pathname'
require 'simplecov' if ENV['COVERAGE']
require 'rspec'
require 'loggability/spechelpers'

require 'treequel'

require_relative 'spec_constants'


### RSpec helper functions.
module Treequel::SpecHelpers
	include Treequel::SpecConstants

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Make a Treequel::Directory that will use the given +conn+ object as its
	### LDAP connection. Also pre-loads the schema object and fixtures some other
	### external data.
	def get_fixtured_directory( conn )
		allow( LDAP::SSLConn ).to receive( :new ).and_return( conn )
		allow( conn ).to receive( :search_ext2 ).
			with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
			and_return( TEST_DSE )
		allow( conn ).to receive( :set_option )

		# Avoid parsing the whole schema with every example
		directory = Treequel.directory( TEST_LDAPURI )
		allow( directory ).to receive( :schema ).and_return( SCHEMA )

		return directory
	end


	### Shorthand method for creating LDAP::Mod DELETE objects 
	def ldap_mod_delete( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, attribute.to_s, values.flatten )
	end


	### Shorthand method for creating LDAP::Mod REPLACE objects 
	def ldap_mod_replace( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_REPLACE, attribute.to_s, values.flatten )
	end


	### Shorthand method for creating LDAP::Mod ADD objects 
	def ldap_mod_add( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_ADD, attribute.to_s, values.flatten )
	end

end


### Mock with RSpec
RSpec.configure do |config|
	include Treequel::SpecConstants

	SPEC_DIR = Pathname( __FILE__ ).dirname
	SPEC_DATA_DIR = SPEC_DIR + 'data'

	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end
	config.expect_with( :rspec ) do |expect|
		expect.syntax = :expect
	end

	config.include( Loggability::SpecHelpers )
	config.include( Treequel::SpecHelpers )

	c.filter_run_excluding( :mri_only ) if
		defined?( RUBY_ENGINE ) && RUBY_ENGINE != 'ruby'
	c.filter_run_excluding( :sequel ) unless
		Sequel.const_defined?( :Model )

end

# vim: set nosta noet ts=4 sw=4:


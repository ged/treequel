#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
		add_group "Needing tests" do |file|
			file.covered_percent < 90
		end
	end
end

require 'rspec'

require 'treequel'

require 'spec/lib/constants'
require 'spec/lib/matchers'

require 'loggability/spechelpers'


### RSpec helper functions.
module Treequel::SpecHelpers
	include Treequel::TestConstants

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
		LDAP::SSLConn.stub( :new ).and_return( conn )
		conn.stub( :search_ext2 ).
			with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
			and_return( TEST_DSE )
		conn.stub( :set_option )

		# Avoid parsing the whole schema with every example
		directory = Treequel.directory( TEST_LDAPURI )
		directory.stub( :schema ).and_return( SCHEMA )

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


abort "You need a version of RSpec >= 2.6.0" unless defined?( RSpec )

### Mock with RSpec
RSpec.configure do |c|
	include Treequel::TestConstants,
	        Loggability::SpecHelpers

	c.mock_with :rspec

	c.extend( Treequel::TestConstants )

	c.include( Treequel::TestConstants )
	c.include( Treequel::SpecHelpers )
	c.include( Treequel::Matchers )
	c.include( Loggability::SpecHelpers )

	c.treat_symbols_as_metadata_keys_with_true_values = true

	if RUBY_VERSION >= '1.9.0'
		c.filter_run_excluding( :ruby_18 )
	else
		c.filter_run_excluding( :ruby_19 )
	end

	c.filter_run_excluding( :mri_only ) if
		defined?( RUBY_ENGINE ) && RUBY_ENGINE != 'ruby'
	c.filter_run_excluding( :sequel ) unless
		Sequel.const_defined?( :Model )

end

# vim: set nosta noet ts=4 sw=4:


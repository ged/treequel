#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'yaml'
	require 'ldap'
	require 'ldap/schema'
	require 'treequel/schema'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :debug )
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
	end

	after( :all ) do
		reset_logging()
	end


	it "can parse the schema structure returned from LDAP::Conn#schema" do
		schema_dumpfile = @datadir + 'schema.yml'
		hash = YAML.load_file( schema_dumpfile )
		schemahash = LDAP::Schema.new( hash )

		schema = Treequel::Schema.new( schemahash )

		schema.objectClasses.should have( 298 ).members
		pending "implementation of the rest of the schema-object classes" do
			schema.ldapSyntaxes.should have( 11 ).members
			schema.matchingRuleUse.should have( 11 ).members
			schema.attributeTypes.should have( 11 ).members
			schema.matchingRules.should have( 11 ).members
		end
	end

end


# vim: set nosta noet ts=4 sw=4:

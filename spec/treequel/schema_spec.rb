#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
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
		setup_logging( :fatal )
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
	end

	after( :all ) do
		reset_logging()
	end

	TEST_NUMERICOID = '1.12.3.8.16.1.1.5'
	TEST_DESCR      = 'objectClass'
	TEST_OIDLIST    = %:( #{TEST_DESCR} $ objectCaste $ #{TEST_NUMERICOID} )  :

	it "can parse the schema structure returned from LDAP::Conn#schema" do
		schema_dumpfile = @datadir + 'schema.yml'
		hash = YAML.load_file( schema_dumpfile )
		schemahash = LDAP::Schema.new( hash )

		schema = Treequel::Schema.new( schemahash )

		schema.object_classes.should have( 298 ).members
		schema.attribute_types.should have( 1085 ).members
		schema.matching_rules.should have( 72 ).members
		schema.matching_rule_uses.should have( 54 ).members
		schema.ldap_syntaxes.should have( 31 ).members

		schema.operational_attribute_types.should have( 31 ).members
	end


	it "can parse the schema structure returned from LDAP::Conn#schema even under $SAFE >= 1" do
		schema_dumpfile = @datadir + 'schema.yml'
		hash = YAML.load_file( schema_dumpfile )

		schema = nil
		Thread.new do
			Thread.current.abort_on_exception = true
			$SAFE = 1
			schemahash = LDAP::Schema.new( hash )
			schema = Treequel::Schema.new( schemahash )
		end.join

		schema.object_classes.should have( 298 ).members
		schema.attribute_types.should have( 1085 ).members
		schema.matching_rules.should have( 72 ).members
		schema.matching_rule_uses.should have( 54 ).members
		schema.ldap_syntaxes.should have( 31 ).members

		schema.operational_attribute_types.should have( 31 ).members
	end


	it "can parse a valid oidlist" do
		oids = Treequel::Schema.parse_oids( TEST_OIDLIST )
		oids.should have(3).members
		oids.should == [ :objectClass, :objectCaste, TEST_NUMERICOID ]
	end

	it "returns an empty Array if oidlist it's asked to parse is nil" do
		Treequel::Schema.parse_oids( nil ).should == []
	end

	it "raises an exception if it's asked to parse an invalid oidlist" do
		expect do
			Treequel::Schema.parse_oids( %Q{my name is Jorma, I'm the sensitive one} )
		end.to raise_error( Treequel::ParseError, /oidlist/i )
	end


	it "keeps a numeric OID as a String when parsing it" do
		Treequel::Schema.parse_oid( TEST_NUMERICOID ).should be_a( String )
		Treequel::Schema.parse_oid( TEST_NUMERICOID ).should == TEST_NUMERICOID
	end

	it "transforms a named OID as a Symbol when parsing it" do
		Treequel::Schema.parse_oid( TEST_DESCR ).should be_a( Symbol )
		Treequel::Schema.parse_oid( TEST_DESCR ).should == TEST_DESCR.to_sym
	end

end


# vim: set nosta noet ts=4 sw=4:

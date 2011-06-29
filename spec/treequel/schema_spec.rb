#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema'


describe Treequel::Schema do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :warn )
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
	end

	before( :each ) do
		@strict_flag = Treequel::Schema.strict_parse_mode?
	end

	after( :each ) do
		Treequel::Schema.strict_parse_mode = @strict_flag
	end

	after( :all ) do
		reset_logging()
	end

	### Constants

	# Some simple parser-testing values
	TEST_NUMERICOID = '1.12.3.8.16.1.1.5'
	TEST_DESCR      = 'objectClass'
	TEST_OIDLIST    = %:( #{TEST_DESCR} $ objectCaste $ #{TEST_NUMERICOID} )  :

	# The malformed objectClass from RFC2926, for testing schema-parsing lenience
	BAD_OBJECTCLASS = "( 1.3.6.1.4.1.6252.2.27.6.2.1 NAME 'slpService' " +
		"DESC 'parent superclass for SLP services' ABSTRACT SUP top MUST " +
		" ( template-major-version-number $ template-minor-version-number " +
		"$ description $ template-url-syntax $ service-advert-service-type " +
		"$ service-advert-scopes ) MAY ( service-advert-url-authenticator " +
		"$ service-advert-attribute-authenticator ) X-ORIGIN 'RFC 2926' )"

	### Matchers

	RSpec::Matchers.define( :be_lenient ) do
		match do |actual|
			!actual.strict_parse_mode?
		end
	end


	### Examples

	it "defaults to lenient schema-parsing" do
		Treequel::Schema.should be_lenient()
	end

	it "can be told to propagate schema-parsing failures for easier problem-detection" do
		Treequel::Schema.strict_parse_mode = true
		Treequel::Schema.should_not be_lenient()
	end


	it "doesn't propagate parse errors while in lenient schema-parsing mode" do
		schema = Treequel::Schema.new( 'objectClasses'   => [BAD_OBJECTCLASS],
		                               'attributeTypes'  => [], 
		                               'ldapSyntaxes'    => [], 
		                               'matchingRules'   => [], 
		                               'matchingRuleUse' => [] )
		schema.should be_a( Treequel::Schema )
		schema.object_classes.keys.should_not include( 'slpService' )
	end

	it "propagates parse errors while in strict schema-parsing mode" do
		Treequel::Schema.strict_parse_mode = true
		expect {
			Treequel::Schema.new( 'objectClasses' => [BAD_OBJECTCLASS] )
		}.to raise_exception( Treequel::ParseError, /malformed objectClass/i )
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



	context "OpenLDAP schema" do
		before( :all ) do
			@schema_dumpfile = @datadir + 'schema.yml'
			@hash = YAML.load_file( @schema_dumpfile )
			@schemahash = LDAP::Schema.new( @hash )
			@schemahash.freeze
			@schema = Treequel::Schema.new( @schemahash )
		end

		it "can parse the schema structure returned from LDAP::Conn#schema" do
			@schema.object_classes.values.uniq.should have( @hash['objectClasses'].length ).members
			@schema.attribute_types.values.uniq.should have( @hash['attributeTypes'].length ).members
			@schema.matching_rules.values.uniq.should have( @hash['matchingRules'].length ).members
			@schema.matching_rule_uses.values.uniq.should have( @hash['matchingRuleUse'].length ).members
			@schema.ldap_syntaxes.values.uniq.should have( @hash['ldapSyntaxes'].length ).members

			dirop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE directoryOperation') }
			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dSAOperation') }
			distop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE distributedOperation') }
			op_attrcount = dirop_count + dsaop_count + distop_count

			@schema.operational_attribute_types.should have( op_attrcount ).members
		end


		it "can parse the schema structure returned from LDAP::Conn#schema even under $SAFE >= 1",
			:mri_only => true do
			schema = nil
			Thread.new do
				Thread.current.abort_on_exception = true
				$SAFE = 1
				schemahash = LDAP::Schema.new( @hash )
				schema = Treequel::Schema.new( schemahash )
			end.join

			schema.should be_an_instance_of( Treequel::Schema )
		end
	end

	context "ActiveDirectory schema" do

		before( :all ) do
			@schema_dumpfile = @datadir + 'ad_schema.yml'
			@hash = YAML.load_file( @schema_dumpfile )
			@schemahash = LDAP::Schema.new( @hash )
			@schema = Treequel::Schema.new( @schemahash )
		end

		it "can parse an ActiveDirectory schema structure, too" do
			@schema.object_classes.values.uniq.should have( @hash['objectClasses'].length ).members
			@schema.attribute_types.values.uniq.should have( @hash['attributeTypes'].length ).members

			# AD doesn't have these in its subSchema
			@schema.matching_rules.should be_empty()
			@schema.matching_rule_uses.should be_empty()
			@schema.ldap_syntaxes.should be_empty()
			@schema.operational_attribute_types.should be_empty()
		end

	end


	# Dumped from an OpenDS 2.2 server with the included 'test data' -- dunno if that's
	# representative of schemas one would find in the wild, but it doesn't parse as-is
	# currently because of (at least) the objectClasses from RFCs 2696, 3112, 3712, and 
	# draft-howard-rfc2307bi
	context "OpenDS schema" do

		before( :all ) do
			@schema_dumpfile = @datadir + 'opends.yml'
			@hash = YAML.load_file( @schema_dumpfile )
			@schemahash = LDAP::Schema.new( @hash )
		end

		it "can parse an OpenDS schema structure, too" do
			@schema = Treequel::Schema.new( @schemahash )

			@schema.object_classes.values.uniq.should have( @hash['objectClasses'].length ).members
			@schema.attribute_types.values.uniq.should have( @hash['attributeTypes'].length ).members
			@schema.matching_rules.values.uniq.should have( @hash['matchingRules'].length ).members
			@schema.ldap_syntaxes.values.uniq.should have( @hash['ldapSyntaxes'].length ).members

			@schema.matching_rule_uses.should be_empty()

			# Not yet supported			
			# @schema.dit_structure_rules.values.uniq.should have( @hash['dITStructureRules'].length ).members
			# @schema.dit_content_rules.values.uniq.should have( @hash['dITContentRules'].length ).members
			# @schema.name_forms.values.uniq.should have( @hash['nameForms'].length ).members

			dirop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE directoryOperation') }
			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dSAOperation') }
			distop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE distributedOperation') }
			op_attrcount = dirop_count + dsaop_count + distop_count

			@schema.operational_attribute_types.should have( op_attrcount ).members
		end

	end


	# Attribute types and matching rules from ticket #11
	context "ticket 11 schema artifacts" do

		before( :all ) do
			@schema_dumpfile = @datadir + 'ticket11.yml'
			@hash = YAML.load_file( @schema_dumpfile )
			@schemahash = LDAP::Schema.new( @hash )
			@schema = Treequel::Schema.new( @schemahash )
		end

		it "can parse schema artifacts from ticket 11" do
			@schema.attribute_types.values.uniq.should have( @hash['attributeTypes'].length ).members
			@schema.matching_rules.values.uniq.should have( @hash['matchingRules'].length ).members

			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dsaOperation') }

			@schema.operational_attribute_types.should have( dsaop_count ).members
		end

	end


end


# vim: set nosta noet ts=4 sw=4:

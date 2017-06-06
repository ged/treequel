#!/usr/bin/env ruby

require_relative '../spec_helpers'


require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema'


describe Treequel::Schema do
	include Treequel::SpecHelpers

	before( :all ) do
		@datadir = Pathname( __FILE__ ).dirname.parent + 'data'
	end

	before( :each ) do
		@strict_flag = Treequel::Schema.strict_parse_mode?
	end

	after( :each ) do
		Treequel::Schema.strict_parse_mode = @strict_flag
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
		expect( Treequel::Schema ).to be_lenient()
	end

	it "can be told to propagate schema-parsing failures for easier problem-detection" do
		Treequel::Schema.strict_parse_mode = true
		expect( Treequel::Schema ).to_not be_lenient()
	end


	it "doesn't propagate parse errors while in lenient schema-parsing mode" do
		schema = Treequel::Schema.new( 'objectClasses'   => [BAD_OBJECTCLASS],
		                               'attributeTypes'  => [], 
		                               'ldapSyntaxes'    => [], 
		                               'matchingRules'   => [], 
		                               'matchingRuleUse' => [] )
		expect( schema ).to be_a( Treequel::Schema )
		expect( schema.object_classes.keys ).to_not include( 'slpService' )
	end

	it "propagates parse errors while in strict schema-parsing mode" do
		Treequel::Schema.strict_parse_mode = true
		expect {
			Treequel::Schema.new( 'objectClasses' => [BAD_OBJECTCLASS] )
		}.to raise_exception( Treequel::ParseError, /malformed objectClass/i )
	end

	it "can parse a valid oidlist" do
		oids = Treequel::Schema.parse_oids( TEST_OIDLIST )
		expect( oids.length ).to eq( 3 )
		expect( oids ).to eq( [ :objectClass, :objectCaste, TEST_NUMERICOID ] )
	end

	it "returns an empty Array if oidlist it's asked to parse is nil" do
		expect( Treequel::Schema.parse_oids( nil ) ).to eq( [] )
	end

	it "raises an exception if it's asked to parse an invalid oidlist" do
		expect do
			Treequel::Schema.parse_oids( %Q{my name is Jorma, I'm the sensitive one} )
		end.to raise_error( Treequel::ParseError, /oidlist/i )
	end


	it "keeps a numeric OID as a String when parsing it" do
		expect( Treequel::Schema.parse_oid( TEST_NUMERICOID ) ).to be_a( String )
		expect( Treequel::Schema.parse_oid( TEST_NUMERICOID ) ).to eq( TEST_NUMERICOID )
	end

	it "transforms a named OID as a Symbol when parsing it" do
		expect( Treequel::Schema.parse_oid( TEST_DESCR ) ).to be_a( Symbol )
		expect( Treequel::Schema.parse_oid( TEST_DESCR ) ).to eq( TEST_DESCR.to_sym )
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
			expect( @schema.object_classes.values.uniq.length ).to eq( @hash['objectClasses'].length )
			expect( @schema.attribute_types.values.uniq.length ).to eq( @hash['attributeTypes'].length )
			expect( @schema.matching_rules.values.uniq.length ).to eq( @hash['matchingRules'].length )
			expect( @schema.matching_rule_uses.values.uniq.length ).to eq( @hash['matchingRuleUse'].length )
			expect( @schema.ldap_syntaxes.values.uniq.length ).to eq( @hash['ldapSyntaxes'].length )

			dirop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE directoryOperation') }
			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dSAOperation') }
			distop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE distributedOperation') }
			op_attrcount = dirop_count + dsaop_count + distop_count

			expect( @schema.operational_attribute_types.length ).to eq( op_attrcount )
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

			expect( schema ).to be_an_instance_of( Treequel::Schema )
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
			expect( @schema.object_classes.values.uniq.length ).to eq( @hash['objectClasses'].length )
			expect( @schema.attribute_types.values.uniq.length ).to eq( @hash['attributeTypes'].length )

			# AD doesn't have these in its subSchema
			expect( @schema.matching_rules ).to be_empty()
			expect( @schema.matching_rule_uses ).to be_empty()
			expect( @schema.ldap_syntaxes ).to be_empty()
			expect( @schema.operational_attribute_types ).to be_empty()
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

			expect( @schema.object_classes.values.uniq.length ).to eq( @hash['objectClasses'].length )
			expect( @schema.attribute_types.values.uniq.length ).to eq( @hash['attributeTypes'].length )
			expect( @schema.matching_rules.values.uniq.length ).to eq( @hash['matchingRules'].length )
			expect( @schema.ldap_syntaxes.values.uniq.length ).to eq( @hash['ldapSyntaxes'].length )

			expect( @schema.matching_rule_uses ).to be_empty()

			# Not yet supported			
			# expect( @schema.dit_structure_rules.values.uniq.length ).
			# 	to eq( @hash['dITStructureRules'].length )
			# expect( @schema.dit_content_rules.values.uniq.length ).
			# 	to eq( @hash['dITContentRules'].length )
			# expect( @schema.name_forms.values.uniq.length ).
			# 	to eq( @hash['nameForms'].length )

			dirop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE directoryOperation') }
			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dSAOperation') }
			distop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE distributedOperation') }
			op_attrcount = dirop_count + dsaop_count + distop_count

			expect( @schema.operational_attribute_types.length ).to eq( op_attrcount )
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
			expect( @schema.attribute_types.values.uniq.length ).to eq( @hash['attributeTypes'].length )
			expect( @schema.matching_rules.values.uniq.length ).to eq( @hash['matchingRules'].length )

			dsaop_count = @hash['attributeTypes'].
				count {|type| type.index('USAGE dsaOperation') }

			expect( @schema.operational_attribute_types.length ).to eq( dsaop_count )
		end

	end


end


# vim: set nosta noet ts=4 sw=4:

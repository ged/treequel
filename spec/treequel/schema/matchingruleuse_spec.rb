#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/matchingruleuse'


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::MatchingRuleUse do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :fatal )
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		@schema = mock( "treequel schema object" )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'uniqueMemberMatch' matchingRuleUse" do

		UNIQUE_MEMBER_MATCH_DESC = %{( 2.5.13.23 NAME 'uniqueMemberMatch' APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, UNIQUE_MEMBER_MATCH_DESC )
		end

		it "knows what its OID is" do
			@ruleuse.oid.should == '2.5.13.23'
		end

		it "knows what its NAME attribute is" do
			@ruleuse.name.should == :uniqueMemberMatch
		end

		it "knows that it is not obsolete" do
			@ruleuse.should_not be_obsolete()
		end

		it "knows what the OIDs of the attribute types it applies to are" do
			@ruleuse.attr_oids.should == [:uniqueMember]
		end

		it "knows what Treequel::Schema::AttributeType objects it applies to are" do
			@schema.should_receive( :attribute_types ).
				and_return({ :uniqueMember => :a_attrtype_object })
			@ruleuse.attribute_types.should == [ :a_attrtype_object ]
		end

		it "can remake its own schema description" do
			@ruleuse.to_s.should == UNIQUE_MEMBER_MATCH_DESC
		end
	end


	describe "parsed from a matchingRuleUse with a DESC attribute" do
		DESCRIPTIVE_MATCHRULEUSE_DESC = %{( 9.9.9.9.9 DESC 'Woop' APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, DESCRIPTIVE_MATCHRULEUSE_DESC )
		end

		it "knows what its description is" do
			@ruleuse.desc.should == "Woop"
		end

	end


	describe "parsed from a matchingRuleUse with more than one applicable attribute type" do
		PHONENUMBER_MATCHRULEUSE_DESC = %{( 2.5.13.20 NAME 'telephoneNumberMatch' APPLIES } +
			%{( telephoneNumber $ homePhone $ mobile $ pager ) )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, PHONENUMBER_MATCHRULEUSE_DESC )
		end

		it "knows what the OIDs of the attribute types it applies to are" do
			@ruleuse.attr_oids.should have(4).members
			@ruleuse.attr_oids.should include( :telephoneNumber, :homePhone, :mobile, :pager )
		end

		it "knows what Treequel::Schema::AttributeType objects it applies to are" do
			oidmap = {
				:telephoneNumber => :phone_number_attr,
				:homePhone => :home_phone_attr,
				:mobile => :mobile_attr,
				:pager => :pager_attr,
			}
			@schema.should_receive( :attribute_types ).at_least( 4 ).times.
				and_return( oidmap )
			@ruleuse.attribute_types.should have(4).members
			@ruleuse.attribute_types.should include( *oidmap.values )
		end
	end


	describe "parsed from a matchingRuleUse that is marked as OBSOLETE" do
		OBSOLETE_MATCHRULEUSE_DESC = %{( 9.9.9.9.9 OBSOLETE APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, OBSOLETE_MATCHRULEUSE_DESC )
		end

		it "knows that it's obsolete" do
			@ruleuse.should be_obsolete()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

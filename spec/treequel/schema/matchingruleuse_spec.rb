#!/usr/bin/env ruby

require_relative '../../spec_helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/matchingruleuse'


include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::MatchingRuleUse do
	include Treequel::SpecHelpers


	before( :all ) do
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		@schema = double( "treequel schema object" )
	end


	describe "parsed from the 'uniqueMemberMatch' matchingRuleUse" do

		UNIQUE_MEMBER_MATCH_DESC = %{( 2.5.13.23 NAME 'uniqueMemberMatch' APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, UNIQUE_MEMBER_MATCH_DESC )
		end

		it "knows what its OID is" do
			expect( @ruleuse.oid ).to eq( '2.5.13.23' )
		end

		it "knows what its NAME attribute is" do
			expect( @ruleuse.name ).to eq( :uniqueMemberMatch )
		end

		it "knows that it is not obsolete" do
			expect( @ruleuse ).to_not be_obsolete()
		end

		it "knows what the OIDs of the attribute types it applies to are" do
			expect( @ruleuse.attr_oids ).to eq( [:uniqueMember] )
		end

		it "knows what Treequel::Schema::AttributeType objects it applies to are" do
			expect( @schema ).to receive( :attribute_types ).
				and_return({ :uniqueMember => :a_attrtype_object })
			expect( @ruleuse.attribute_types ).to eq( [ :a_attrtype_object ] )
		end

		it "can remake its own schema description" do
			expect( @ruleuse.to_s ).to eq( UNIQUE_MEMBER_MATCH_DESC )
		end
	end


	describe "parsed from a matchingRuleUse with a DESC attribute" do
		DESCRIPTIVE_MATCHRULEUSE_DESC = %{( 9.9.9.9.9 DESC 'Woop' APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, DESCRIPTIVE_MATCHRULEUSE_DESC )
		end

		it "knows what its description is" do
			expect( @ruleuse.desc ).to eq( "Woop" )
		end

	end


	describe "parsed from a matchingRuleUse with more than one applicable attribute type" do
		PHONENUMBER_MATCHRULEUSE_DESC = %{( 2.5.13.20 NAME 'telephoneNumberMatch' APPLIES } +
			%{( telephoneNumber $ homePhone $ mobile $ pager ) )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, PHONENUMBER_MATCHRULEUSE_DESC )
		end

		it "knows what the OIDs of the attribute types it applies to are" do
			expect( @ruleuse.attr_oids.length ).to eq( 4 )
			expect( @ruleuse.attr_oids ).to include( :telephoneNumber, :homePhone, :mobile, :pager )
		end

		it "knows what Treequel::Schema::AttributeType objects it applies to are" do
			oidmap = {
				:telephoneNumber => :phone_number_attr,
				:homePhone => :home_phone_attr,
				:mobile => :mobile_attr,
				:pager => :pager_attr,
			}
			expect( @schema ).to receive( :attribute_types ).at_least( 4 ).times.
				and_return( oidmap )
			expect( @ruleuse.attribute_types.length ).to eq( 4 )
			expect( @ruleuse.attribute_types ).to include( *oidmap.values )
		end
	end


	describe "parsed from a matchingRuleUse that is marked as OBSOLETE" do
		OBSOLETE_MATCHRULEUSE_DESC = %{( 9.9.9.9.9 OBSOLETE APPLIES uniqueMember )}

		before( :each ) do
			@ruleuse = Treequel::Schema::MatchingRuleUse.parse( @schema, OBSOLETE_MATCHRULEUSE_DESC )
		end

		it "knows that it's obsolete" do
			expect( @ruleuse ).to be_obsolete()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

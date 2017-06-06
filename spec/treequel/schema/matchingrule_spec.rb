#!/usr/bin/env ruby

require_relative '../../spec_helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/matchingrule'


include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::MatchingRule do
	include Treequel::SpecHelpers


	before( :all ) do
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		@schema = double( "treequel schema object" )
	end


	describe "parsed from the 'octetStringMatch' matchingRule" do

		OCTETSTRINGMATCH_RULE = %{( 2.5.13.17 NAME 'octetStringMatch' } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, OCTETSTRINGMATCH_RULE )
		end

		it "knows what OID corresponds to the type" do
			expect( @rule.oid ).to eq( '2.5.13.17' )
		end

		it "knows what its NAME attribute is" do
			expect( @rule.name ).to eq( :octetStringMatch )
		end

		it "knows what its SYNTAX OID is" do
			expect( @rule.syntax_oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.40' )
		end

		it "knows what its syntax is" do
			expect( @schema ).to receive( :ldap_syntaxes ).
				and_return({ '1.3.6.1.4.1.1466.115.121.1.40' => :the_syntax })
			expect( @rule.syntax ).to eq( :the_syntax )
		end

		it "knows that it is not obsolete" do
			expect( @rule ).to_not be_obsolete()
		end

		it "can remake its own schema description" do
			expect( @rule.to_s ).to eq( OCTETSTRINGMATCH_RULE )
		end
	end

	describe "parsed from an matchingRule that has a DESC attribute" do

		DESCRIBED_RULE = %{( 9.9.9.9.9 DESC 'Hot dog propulsion device' SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, DESCRIBED_RULE )
		end

		it "knows what its DESC attribute" do
			expect( @rule.desc ).to eq( 'Hot dog propulsion device' )
		end

	end

	describe "parsed from an matchingRule that doesn't have a NAME attribute" do

		ANONYMOUS_RULE = %{( 9.9.9.9.9 SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, ANONYMOUS_RULE )
		end

		it "knows that its NAME is nil" do
			expect( @rule.name ).to be_nil()
		end

	end

	describe "parsed from an matchingRule that has a list as the value of its NAME attribute" do

		MULTINAME_MATCHINGRULE = %{( 1.1.1.1 NAME ('firstname' 'secondname') SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, MULTINAME_MATCHINGRULE )
		end

		it "knows what both names are" do
			expect( @rule.names.length ).to eq( 2 )
			expect( @rule.names ).to include( :firstname, :secondname )
		end

		it "returns the first of its names for the #name method" do
			expect( @rule.name ).to eq( :firstname )
		end

	end

	describe "parsed from an matchingRule that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_MATCHINGRULE = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, ESCAPED_DESC_MATCHINGRULE )
		end

		it "unscapes the escaped characters" do
			expect( @rule.desc ).to eq( %{This spec's example, which includes a \\ character.} )
		end

	end

	describe "parsed from an matchingRule that has the OBSOLETE attribute" do

		OBSOLETE_MATCHINGRULE = %{( 1.1.1.1 OBSOLETE SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, OBSOLETE_MATCHINGRULE )
		end

		it "knows that it's obsolete" do
			expect( @rule ).to be_obsolete()
		end

	end


	describe "parsed from one of the matching rules from the OpenDS schema" do

		TIME_BASED_MATCHINGRULE = %{( 1.3.6.1.4.1.26027.1.4.5 NAME } +
			%{( 'relativeTimeGTOrderingMatch' 'relativeTimeOrderingMatch.gt' ) } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.24 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, TIME_BASED_MATCHINGRULE )
		end

		it "knows that it's obsolete" do
			expect( @rule.name ).to eq( :relativeTimeGTOrderingMatch )
			expect( @rule.names ).to include( :relativeTimeGTOrderingMatch, :'relativeTimeOrderingMatch.gt' )
			expect( @rule.syntax_oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.24' )
		end

	end


	describe "parsed from one of the matching rules from issue 11" do

		NAME_AND_OID_MATCHINGRULE = %{( 1.3.6.1.4.1.42.2.27.9.4.0.3 } +
			%{NAME 'caseExactOrderingMatch-2.16.840.1.113730.3.3.2.0.3' } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, NAME_AND_OID_MATCHINGRULE )
		end

		it "knows what its rule is" do
			expect( @rule.name ).to eq( 'caseExactOrderingMatch-2.16.840.1.113730.3.3.2.0.3'.to_sym )
			expect( @rule.syntax_oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.15' )
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

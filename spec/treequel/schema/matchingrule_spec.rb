#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/matchingrule'


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::MatchingRule do
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


	describe "parsed from the 'octetStringMatch' matchingRule" do

		OCTETSTRINGMATCH_RULE = %{( 2.5.13.17 NAME 'octetStringMatch' } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, OCTETSTRINGMATCH_RULE )
		end

		it "knows what OID corresponds to the type" do
			@rule.oid.should == '2.5.13.17'
		end

		it "knows what its NAME attribute is" do
			@rule.name.should == :octetStringMatch
		end

		it "knows what its SYNTAX OID is" do
			@rule.syntax_oid.should == '1.3.6.1.4.1.1466.115.121.1.40'
		end

		it "knows what its syntax is" do
			@schema.should_receive( :ldap_syntaxes ).
				and_return({ '1.3.6.1.4.1.1466.115.121.1.40' => :the_syntax })
			@rule.syntax.should == :the_syntax
		end

		it "knows that it is not obsolete" do
			@rule.should_not be_obsolete()
		end

		it "can remake its own schema description" do
			@rule.to_s.should == OCTETSTRINGMATCH_RULE
		end
	end

	describe "parsed from an matchingRule that has a DESC attribute" do

		DESCRIBED_RULE = %{( 9.9.9.9.9 DESC 'Hot dog propulsion device' SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, DESCRIBED_RULE )
		end

		it "knows what its DESC attribute" do
			@rule.desc.should == 'Hot dog propulsion device'
		end

	end

	describe "parsed from an matchingRule that doesn't have a NAME attribute" do

		ANONYMOUS_RULE = %{( 9.9.9.9.9 SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, ANONYMOUS_RULE )
		end

		it "knows that its NAME is nil" do
			@rule.name.should be_nil()
		end

	end

	describe "parsed from an matchingRule that has a list as the value of its NAME attribute" do

		MULTINAME_MATCHINGRULE = %{( 1.1.1.1 NAME ('firstname' 'secondname') SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, MULTINAME_MATCHINGRULE )
		end

		it "knows what both names are" do
			@rule.names.should have(2).members
			@rule.names.should include( :firstname, :secondname )
		end

		it "returns the first of its names for the #name method" do
			@rule.name.should == :firstname
		end

	end

	describe "parsed from an matchingRule that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_MATCHINGRULE = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, ESCAPED_DESC_MATCHINGRULE )
		end

		it "unscapes the escaped characters" do
			@rule.desc.should == %{This spec's example, which includes a \\ character.}
		end

	end

	describe "parsed from an matchingRule that has the OBSOLETE attribute" do

		OBSOLETE_MATCHINGRULE = %{( 1.1.1.1 OBSOLETE SYNTAX 9.9.9.9.9.9 )}

		before( :each ) do
			@rule = Treequel::Schema::MatchingRule.parse( @schema, OBSOLETE_MATCHINGRULE )
		end

		it "knows that it's obsolete" do
			@rule.should be_obsolete()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

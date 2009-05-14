#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

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
	require 'treequel/schema/attributetype'
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

describe Treequel::Schema::AttributeType do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :debug )
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'objectClass' attributeType" do

		OBJECTCLASS_ATTRTYPE = %{( 2.5.4.0 NAME 'objectClass' } +
			%{DESC 'RFC2256: object classes of the entity' } +
			%{EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 )}

		before( :each ) do
			@attrtype = Treequel::Schema::AttributeType.parse( OBJECTCLASS_ATTRTYPE )
		end

		it "knows what OID corresponds to the type" do
			@attrtype.oid.should == '2.5.4.0'
		end

		it "knows what its NAME attribute is" do
			@attrtype.name.should == :objectClass
		end

		it "knows what its DESC attribute is" do
			@attrtype.desc.should == 'RFC2256: object classes of the entity'
		end

		it "knows what the name of its equality matching rule is" do
			@attrtype.eqmatch_oid.should == :objectIdentifierMatch
		end

		it "returns a matchingRule object for its equality matching rule" do
			pending "implementation of Treequel::Schema::MatchingRule" do
				@attrtype.equality_matching_rule.
					should be_an_instance_of( Treequel::Schema::MatchingRule )
			end
		end

		it "knows that it is not obsolete" do
			@attrtype.should_not be_obsolete()
		end

	end


	describe "parsed from an attributeType that has a SUP attribute" do
		it "takes the value of the equality matching rule from its supertype"
		it "takes the value of the order matching rule from its supertype"
		it "takes the value of the substring matching rule from its supertype"
	end


	describe "parsed from an attributeType that has a list as the value of its NAME attribute" do

		MULTINAME_ATTRIBUTETYPE = %{( 1.1.1.1 NAME ('firstname' 'secondname') )}

		before( :each ) do
			@attrtype = Treequel::Schema::AttributeType.parse( MULTINAME_ATTRIBUTETYPE )
		end

		it "knows what both names are" do
			@attrtype.names.should have(2).members
			@attrtype.names.should include( :firstname, :secondname )
		end

		it "returns the first of its names for the #name method" do
			@attrtype.name.should == :firstname
		end

	end

	describe "parsed from an attributeType that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_ATTRIBUTETYPE = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@attrtype = Treequel::Schema::AttributeType.parse( ESCAPED_DESC_ATTRIBUTETYPE )
		end

		it "unscapes the escaped characters" do
			@attrtype.desc.should == %{This spec's example, which includes a \\ character.}
		end

	end

	describe "parsed from an attributeType that has the OBSOLETE attribute" do

		OBSOLETE_ATTRIBUTETYPE = %{( 1.1.1.1 OBSOLETE )}

		before( :each ) do
			@attrtype = Treequel::Schema::AttributeType.parse( OBSOLETE_ATTRIBUTETYPE )
		end

		it "knows that it's obsolete" do
			@attrtype.should be_obsolete()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

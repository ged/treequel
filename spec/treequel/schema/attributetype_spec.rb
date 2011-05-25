#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/attributetype'


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::AttributeType do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@schema = mock( "treequel schema object" )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'objectClass' attributeType" do

		OBJECTCLASS_ATTRTYPE = %{( 2.5.4.0 NAME 'objectClass' } +
			%{DESC 'RFC2256: object classes of the entity' } +
			%{EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, OBJECTCLASS_ATTRTYPE )
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

		it "knows it doesn't have a superior type" do
			@attrtype.sup.should be_nil()
		end

		it "knows what the name of its equality matching rule is" do
			@attrtype.eqmatch_oid.should == :objectIdentifierMatch
		end

		it "returns a matchingRule object from its schema for its equality matching rule" do
			@schema.should_receive( :matching_rules ).
				and_return({ :objectIdentifierMatch => :a_matching_rule })
			@attrtype.equality_matching_rule.should == :a_matching_rule
		end

		it "doesn't have an order matchingRule" do
			@attrtype.ordering_matching_rule.should be_nil()
		end

		it "returns a matchingRule object from its schema for its substring matching rule" do
			@attrtype.substr_matching_rule.should be_nil()
		end

		it "knows that it is not obsolete" do
			@attrtype.should_not be_obsolete()
		end

		it "knows what its syntax OID is" do
			@attrtype.syntax_oid.should == '1.3.6.1.4.1.1466.115.121.1.38'
		end

		it "knows that its syntax length is not set" do
			@attrtype.syntax_len.should be_nil()
		end

		it "returns an ldapSyntax object from its schema for its syntax" do
			@schema.should_receive( :ldap_syntaxes ).
				and_return({ '1.3.6.1.4.1.1466.115.121.1.38' => :the_syntax })
			@attrtype.syntax.should == :the_syntax
		end

		it "can remake its own schema description" do
			@attrtype.to_s.sub( /USAGE \w+\s*/i, '' ).should == OBJECTCLASS_ATTRTYPE
		end

		it "knows that it's a user application attribute type" do
			@attrtype.should be_user()
		end

		it "knows that it's not an operational attribute type" do
			@attrtype.should_not be_operational()
		end

		it "knows that it's not a directory operational attribute type" do
			@attrtype.should_not be_directory_operational()
		end

		it "knows that it's not a distributed attribute type" do
			@attrtype.should_not be_distributed_operational()
		end

		it "knows that it's not a DSA attribute type" do
			@attrtype.should_not be_dsa_operational()
		end
	end


	describe "parsed from an attributeType that has a SUP attribute" do
		DERIVED_ATTRTYPE = %{( 1.11.2.11.1 SUP aSuperType } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DERIVED_ATTRTYPE )
		end

		it "can fetch its superior type from its schema" do
			@schema.should_receive( :attribute_types ).
				and_return({ :aSuperType => :the_superior_type })
			@attrtype.sup.should == :the_superior_type
		end

		it "returns a matchingRule object from its supertype's equality matching rule if it " +
		   "doesn't have one" do
			supertype = mock( "superior attribute type object" )
			@schema.should_receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			supertype.should_receive( :equality_matching_rule ).and_return( :a_matching_rule )

			@attrtype.equality_matching_rule.should == :a_matching_rule
		end

		it "returns a matchingRule object from its supertype's ordering matching rule if it " +
		   "doesn't have one" do
			supertype = mock( "superior attribute type object" )
			@schema.should_receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			supertype.should_receive( :ordering_matching_rule ).and_return( :a_matching_rule )

			@attrtype.ordering_matching_rule.should == :a_matching_rule
		end

		it "returns a matchingRule object from its supertype's substr matching rule if it " +
		   "doesn't have one" do
			supertype = mock( "superior attribute type object" )
			@schema.should_receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			supertype.should_receive( :substr_matching_rule ).and_return( :a_matching_rule )

			@attrtype.substr_matching_rule.should == :a_matching_rule
		end

	end


	describe "parsed from an attributeType that has a SUP attribute but no SYNTAX" do
		DERIVED_NOSYN_ATTRTYPE = %{( 1.11.2.11.1 SUP aSuperType )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DERIVED_NOSYN_ATTRTYPE )
		end

		it "fetches its SYNTAX from its supertype" do
			supertype = mock( "supertype object" )
			@schema.should_receive( :attribute_types ).at_least( :once ).
				and_return({ :aSuperType => supertype })
			supertype.should_receive( :syntax ).and_return( :the_syntax )

			@attrtype.syntax.should == :the_syntax
		end

	end

	describe "parsed from an attributeType that has a list as the value of its NAME attribute" do

		MULTINAME_ATTRIBUTETYPE = %{( 1.1.1.1 NAME ('firstName' 'secondName') )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, MULTINAME_ATTRIBUTETYPE )
		end

		it "knows what both names are" do
			@attrtype.names.should have(2).members
			@attrtype.names.should include( :firstName, :secondName )
		end

		it "returns the first of its names for the #name method" do
			@attrtype.name.should == :firstName
		end

		it "knows how to build a normalized list of its names" do
			@attrtype.normalized_names.should == [ :firstname, :secondname ]
		end

		it "knows when a name is valid" do
			@attrtype.valid_name?( 'first name' ).should be_true()
		end

		it "knows when a name is invalid" do
			@attrtype.valid_name?( :name2 ).should be_false()
		end
	end

	describe "parsed from an attributeType that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_ATTRIBUTETYPE = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, ESCAPED_DESC_ATTRIBUTETYPE )
		end

		it "unscapes the escaped characters" do
			@attrtype.desc.should == %{This spec's example, which includes a \\ character.}
		end

	end

	describe "parsed from an attributeType that has the OBSOLETE attribute" do

		OBSOLETE_ATTRIBUTETYPE = %{( 1.1.1.1 OBSOLETE )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, OBSOLETE_ATTRIBUTETYPE )
		end

		it "knows that it's obsolete" do
			@attrtype.should be_obsolete()
		end

	end

	describe "parsed from an attributeType that has the 'directoryOperation' USAGE attribute" do

		DIRECTORY_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE directoryOperation )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DIRECTORY_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			@attrtype.should_not be_user()
		end

		it "knows that it's an operational attribute type" do
			@attrtype.should be_operational()
		end

		it "knows that it's a directory operational attribute type" do
			@attrtype.should be_directory_operational()
		end

		it "knows that it's NOT a distributed operational attribute type" do
			@attrtype.should_not be_distributed_operational()
		end

		it "knows that it's NOT a DSA-specific operational attribute type" do
			@attrtype.should_not be_dsa_operational()
		end

	end

	describe "parsed from an attributeType that has the 'distributedOperation' USAGE attribute" do

		DISTRIBUTED_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE distributedOperation )}

		before( :each ) do
			@attrtype = described_class.
				parse( @schema, DISTRIBUTED_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			@attrtype.should_not be_user()
		end

		it "knows that it's an operational attribute type" do
			@attrtype.should be_operational()
		end

		it "knows that it's NOT a directory operational attribute type" do
			@attrtype.should_not be_directory_operational()
		end

		it "knows that it's a distributed operational attribute type" do
			@attrtype.should be_distributed_operational()
		end

		it "knows that it's NOT a DSA-specific operational attribute type" do
			@attrtype.should_not be_dsa_operational()
		end

	end

	describe "parsed from an attributeType that has the 'dSAOperation' USAGE attribute" do

		DSASPECIFIC_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE dSAOperation )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DSASPECIFIC_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			@attrtype.should_not be_user()
		end

		it "knows that it's an operational attribute type" do
			@attrtype.should be_operational()
		end

		it "knows that it's NOT a directory operational attribute type" do
			@attrtype.should_not be_directory_operational()
		end

		it "knows that it's NOT a distributed operational attribute type" do
			@attrtype.should_not be_distributed_operational()
		end

		it "knows that it's a DSA-specific operational attribute type" do
			@attrtype.should be_dsa_operational()
		end

	end

	describe "parsed from the 'supportedLDAPVersion' attribute type" do

		SUPPORTED_LDAP_VERSION_ATTRIBUTETYPE = %{( 1.3.6.1.4.1.1466.101.120.15 NAME } +
			%{'supportedLDAPVersion' DESC 'Standard LDAP attribute type' SYNTAX } +
			%{1.3.6.1.4.1.1466.115.121.1.27 USAGE dsaOperation X-ORIGIN 'RFC 2252' )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, SUPPORTED_LDAP_VERSION_ATTRIBUTETYPE )
		end

		it "knows what OID corresponds to the type" do
			@attrtype.oid.should == '1.3.6.1.4.1.1466.101.120.15'
		end

		it "knows what its NAME attribute is" do
			@attrtype.name.should == :supportedLDAPVersion
		end

		it "knows what its DESC attribute is" do
			@attrtype.desc.should == 'Standard LDAP attribute type'
		end

		it "knows it doesn't have a superior type" do
			@attrtype.sup.should be_nil()
		end

		it "knows what the name of its equality matching rule is" do
			@attrtype.eqmatch_oid.should be_nil()
		end

	end

	describe "compatibility with malformed declarations: " do

		LDAP_CHANGELOG_ATTRIBUTETYPE = %{
			(   2.16.840.1.113730.3.1.35
				NAME 'changelog'
				DESC 'the distinguished name of the entry which contains
				      the set of entries comprising this server's changelog'
				EQUALITY distinguishedNameMatch
				SYNTAX 'DN'
			)
		}

		it "parses the 'changelog' attribute type from draft-good-ldap-changelog" do
			attrtype = described_class.parse( @schema, LDAP_CHANGELOG_ATTRIBUTETYPE )

			attrtype.should be_a( described_class )
			attrtype.name.should == :changelog
			attrtype.oid.should == '2.16.840.1.113730.3.1.35'
			attrtype.desc.should == %{the distinguished name of the entry which contains } +
				%{the set of entries comprising this server's changelog}
		end

		LDAP_CHANGELOG_CHANGENUMBER_ATTRIBUTETYPE = %{
			( 2.16.840.1.113730.3.1.5
				NAME 'changeNumber'
				DESC 'a number which uniquely identifies a change made to a
				      directory entry'
				SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
				EQUALITY integerMatch
				ORDERING integerOrderingMatch
				SINGLE-VALUE
			)
		}

		it "parses the 'changeNumber' attribute from draft-good-ldap-changelog" do
			attrtype = described_class.parse( @schema, LDAP_CHANGELOG_CHANGENUMBER_ATTRIBUTETYPE )

			attrtype.should be_a( described_class )
			attrtype.name.should == :changeNumber
			attrtype.oid.should == '2.16.840.1.113730.3.1.5'
			attrtype.syntax_oid.should == '1.3.6.1.4.1.1466.115.121.1.27'
			attrtype.desc.should == %{a number which uniquely identifies a change made to a } +
			      %{directory entry}
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

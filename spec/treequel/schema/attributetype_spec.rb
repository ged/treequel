# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/attributetype'


describe Treequel::Schema::AttributeType do
	include Treequel::SpecHelpers


	before( :each ) do
		@schema = double( "treequel schema object" )
	end


	describe "parsed from the 'objectClass' attributeType" do

		OBJECTCLASS_ATTRTYPE = %{( 2.5.4.0 NAME 'objectClass' } +
			%{DESC 'RFC2256: object classes of the entity' } +
			%{EQUALITY objectIdentifierMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, OBJECTCLASS_ATTRTYPE )
		end

		it "knows what OID corresponds to the type" do
			expect( @attrtype.oid ).to eq( '2.5.4.0' )
		end

		it "knows what its NAME attribute is" do
			expect( @attrtype.name ).to eq( :objectClass )
		end

		it "knows what its DESC attribute is" do
			expect( @attrtype.desc ).to eq( 'RFC2256: object classes of the entity' )
		end

		it "knows it doesn't have a superior type" do
			expect( @attrtype.sup ).to be_nil()
		end

		it "knows what the name of its equality matching rule is" do
			expect( @attrtype.eqmatch_oid ).to eq( :objectIdentifierMatch )
		end

		it "returns a matchingRule object from its schema for its equality matching rule" do
			expect( @schema ).to receive( :matching_rules ).
				and_return({ :objectIdentifierMatch => :a_matching_rule })
			expect( @attrtype.equality_matching_rule ).to eq( :a_matching_rule )
		end

		it "doesn't have an order matchingRule" do
			expect( @attrtype.ordering_matching_rule ).to be_nil()
		end

		it "returns a matchingRule object from its schema for its substring matching rule" do
			expect( @attrtype.substr_matching_rule ).to be_nil()
		end

		it "knows that it is not obsolete" do
			expect( @attrtype ).to_not be_obsolete()
		end

		it "knows what its syntax OID is" do
			expect( @attrtype.syntax_oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.38' )
		end

		it "knows that its syntax length is not set" do
			expect( @attrtype.syntax_len ).to be_nil()
		end

		it "returns an ldapSyntax object from its schema for its syntax" do
			expect( @schema ).to receive( :ldap_syntaxes ).
				and_return({ '1.3.6.1.4.1.1466.115.121.1.38' => :the_syntax })
			expect( @attrtype.syntax ).to eq( :the_syntax )
		end

		it "can remake its own schema description" do
			expect( @attrtype.to_s.sub( /USAGE \w+\s*/i, '' ) ).to eq( OBJECTCLASS_ATTRTYPE )
		end

		it "knows that it's a user application attribute type" do
			expect( @attrtype ).to be_user()
		end

		it "knows that it's not an operational attribute type" do
			expect( @attrtype ).to_not be_operational()
		end

		it "knows that it's not a directory operational attribute type" do
			expect( @attrtype ).to_not be_directory_operational()
		end

		it "knows that it's not a distributed attribute type" do
			expect( @attrtype ).to_not be_distributed_operational()
		end

		it "knows that it's not a DSA attribute type" do
			expect( @attrtype ).to_not be_dsa_operational()
		end
	end


	describe "parsed from an attributeType that has a SUP attribute" do
		DERIVED_ATTRTYPE = %{( 1.11.2.11.1 SUP aSuperType } +
			%{SYNTAX 1.3.6.1.4.1.1466.115.121.1.38 )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DERIVED_ATTRTYPE )
		end

		it "can fetch its superior type from its schema" do
			expect( @schema ).to receive( :attribute_types ).
				and_return({ :aSuperType => :the_superior_type })
			expect( @attrtype.sup ).to eq( :the_superior_type )
		end

		it "returns a matchingRule object from its supertype's equality matching rule if it " +
		   "doesn't have one" do
			supertype = double( "superior attribute type object" )
			expect( @schema ).to receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			expect( supertype ).to receive( :equality_matching_rule ).and_return( :a_matching_rule )

			expect( @attrtype.equality_matching_rule ).to eq( :a_matching_rule )
		end

		it "returns a matchingRule object from its supertype's ordering matching rule if it " +
		   "doesn't have one" do
			supertype = double( "superior attribute type object" )
			expect( @schema ).to receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			expect( supertype ).to receive( :ordering_matching_rule ).and_return( :a_matching_rule )

			expect( @attrtype.ordering_matching_rule ).to eq( :a_matching_rule )
		end

		it "returns a matchingRule object from its supertype's substr matching rule if it " +
		   "doesn't have one" do
			supertype = double( "superior attribute type object" )
			expect( @schema ).to receive( :attribute_types ).twice.
				and_return({ :aSuperType => supertype })
			expect( supertype ).to receive( :substr_matching_rule ).and_return( :a_matching_rule )

			expect( @attrtype.substr_matching_rule ).to eq( :a_matching_rule )
		end

	end


	describe "parsed from an attributeType that has a SUP attribute but no SYNTAX" do
		DERIVED_NOSYN_ATTRTYPE = %{( 1.11.2.11.1 SUP aSuperType )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DERIVED_NOSYN_ATTRTYPE )
		end

		it "fetches its SYNTAX from its supertype" do
			supertype = double( "supertype object" )
			expect( @schema ).to receive( :attribute_types ).at_least( :once ).
				and_return({ :aSuperType => supertype })
			expect( supertype ).to receive( :syntax ).and_return( :the_syntax )

			expect( @attrtype.syntax ).to eq( :the_syntax )
		end

	end

	describe "parsed from an attributeType that has a list as the value of its NAME attribute" do

		MULTINAME_ATTRIBUTETYPE = %{( 1.1.1.1 NAME ('firstName' 'secondName') )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, MULTINAME_ATTRIBUTETYPE )
		end

		it "knows what both names are" do
			expect( @attrtype.names.length ).to eq( 2 )
			expect( @attrtype.names ).to include( :firstName, :secondName )
		end

		it "returns the first of its names for the #name method" do
			expect( @attrtype.name ).to eq( :firstName )
		end

		it "knows how to build a normalized list of its names" do
			expect( @attrtype.normalized_names ).to eq( [ :firstname, :secondname ] )
		end

		it "knows when a name is valid" do
			expect( @attrtype.valid_name?( 'first name' ) ).to be_truthy()
		end

		it "knows when a name is invalid" do
			expect( @attrtype.valid_name?( :name2 ) ).to be_falsey()
		end
	end

	describe "parsed from an attributeType that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_ATTRIBUTETYPE = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, ESCAPED_DESC_ATTRIBUTETYPE )
		end

		it "unscapes the escaped characters" do
			expect( @attrtype.desc ).to eq( %{This spec's example, which includes a \\ character.} )
		end

	end

	describe "parsed from an attributeType that has the OBSOLETE attribute" do

		OBSOLETE_ATTRIBUTETYPE = %{( 1.1.1.1 OBSOLETE )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, OBSOLETE_ATTRIBUTETYPE )
		end

		it "knows that it's obsolete" do
			expect( @attrtype ).to be_obsolete()
		end

	end

	describe "parsed from an attributeType that has the 'directoryOperation' USAGE attribute" do

		DIRECTORY_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE directoryOperation )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DIRECTORY_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			expect( @attrtype ).to_not be_user()
		end

		it "knows that it's an operational attribute type" do
			expect( @attrtype ).to be_operational()
		end

		it "knows that it's a directory operational attribute type" do
			expect( @attrtype ).to be_directory_operational()
		end

		it "knows that it's NOT a distributed operational attribute type" do
			expect( @attrtype ).to_not be_distributed_operational()
		end

		it "knows that it's NOT a DSA-specific operational attribute type" do
			expect( @attrtype ).to_not be_dsa_operational()
		end

	end

	describe "parsed from an attributeType that has the 'distributedOperation' USAGE attribute" do

		DISTRIBUTED_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE distributedOperation )}

		before( :each ) do
			@attrtype = described_class.
				parse( @schema, DISTRIBUTED_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			expect( @attrtype ).to_not be_user()
		end

		it "knows that it's an operational attribute type" do
			expect( @attrtype ).to be_operational()
		end

		it "knows that it's NOT a directory operational attribute type" do
			expect( @attrtype ).to_not be_directory_operational()
		end

		it "knows that it's a distributed operational attribute type" do
			expect( @attrtype ).to be_distributed_operational()
		end

		it "knows that it's NOT a DSA-specific operational attribute type" do
			expect( @attrtype ).to_not be_dsa_operational()
		end

	end

	describe "parsed from an attributeType that has the 'dSAOperation' USAGE attribute" do

		DSASPECIFIC_OPERATIONAL_ATTRIBUTETYPE = %{( 1.1.1.1 USAGE dSAOperation )}

		before( :each ) do
			@attrtype = described_class.parse( @schema, DSASPECIFIC_OPERATIONAL_ATTRIBUTETYPE )
		end

		it "knows that it's not a user-application attribute type" do
			expect( @attrtype ).to_not be_user()
		end

		it "knows that it's an operational attribute type" do
			expect( @attrtype ).to be_operational()
		end

		it "knows that it's NOT a directory operational attribute type" do
			expect( @attrtype ).to_not be_directory_operational()
		end

		it "knows that it's NOT a distributed operational attribute type" do
			expect( @attrtype ).to_not be_distributed_operational()
		end

		it "knows that it's a DSA-specific operational attribute type" do
			expect( @attrtype ).to be_dsa_operational()
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
			expect( @attrtype.oid ).to eq( '1.3.6.1.4.1.1466.101.120.15' )
		end

		it "knows what its NAME attribute is" do
			expect( @attrtype.name ).to eq( :supportedLDAPVersion )
		end

		it "knows what its DESC attribute is" do
			expect( @attrtype.desc ).to eq( 'Standard LDAP attribute type' )
		end

		it "knows it doesn't have a superior type" do
			expect( @attrtype.sup ).to be_nil()
		end

		it "knows what the name of its equality matching rule is" do
			expect( @attrtype.eqmatch_oid ).to be_nil()
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

			expect( attrtype ).to be_a( described_class )
			expect( attrtype.name ).to eq( :changelog )
			expect( attrtype.oid ).to eq( '2.16.840.1.113730.3.1.35' )
			expect( attrtype.desc ).to eq(
				%{the distinguished name of the entry which contains } +
				%{the set of entries comprising this server's changelog}
			)
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

			expect( attrtype ).to be_a( described_class )
			expect( attrtype.name ).to eq( :changeNumber )
			expect( attrtype.oid ).to eq( '2.16.840.1.113730.3.1.5' )
			expect( attrtype.syntax_oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.27' )
			expect( attrtype.desc ).to eq(
				%{a number which uniquely identifies a change made to a } +
			    %{directory entry}
			)
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

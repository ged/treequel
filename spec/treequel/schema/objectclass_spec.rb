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
	require 'treequel/schema/objectclass'
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

describe Treequel::Schema::ObjectClass do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :fatal )
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		@schema = mock( "Treequel schema" )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'top' objectClass" do

		TOP_OBJECTCLASS = %{( 2.5.6.0 NAME 'top' DESC 'top of the superclass chain' ABSTRACT } +
			%{MUST objectClass )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, TOP_OBJECTCLASS )
		end

		it "is an AbstractObjectClass because its 'kind' is 'ABSTRACT'" do
			@oc.should be_an_instance_of( Treequel::Schema::AbstractObjectClass )
		end

		it "knows what OID corresponds to the class" do
			@oc.oid.should == '2.5.6.0'
		end

		it "knows what its NAME attribute is" do
			@oc.name.should == :top
		end

		it "knows what its DESC attribute is" do
			@oc.desc.should == 'top of the superclass chain'
		end

		it "knows that it has one MUST attribute" do
			@oc.must_oids.should have( 1 ).member
			@oc.must_oids.should == [ :objectClass ]
		end

		it "returns attribute objects for its MUST OIDs" do
			@schema.should_receive( :attribute_types ).at_least( :once ).
				and_return({ :objectClass => :attribute_type })

			@oc.must.should have( 1 ).member
			@oc.must.should == [ :attribute_type ]
		end

		it "returns attribute objects for its MAY OIDs" do
			@schema.should_receive( :attribute_types ).at_least( :once ).
				and_return({ :objectClass => :attribute_type })

			@oc.must.should have( 1 ).member
			@oc.must.should == [ :attribute_type ]
		end

		it "knows that it doesn't have any MAY attributes" do
			@oc.may_oids.should be_empty()
		end

		it "knows that it is not obsolete" do
			@oc.should_not be_obsolete()
		end

		it "knows that it doesn't have a superclass" do
			@oc.sup.should be_nil()
		end

	end


	describe "parsed from the 'organizationalUnit' objectClass" do

		OU_OBJECTCLASS = %{( 2.5.6.5 NAME 'organizationalUnit' } +
			%{DESC 'RFC2256: an organizational unit' SUP top STRUCTURAL } +
			%{MUST ou MAY ( userPassword $ searchGuide $ seeAlso $ } +
			%{businessCategory $ x121Address $ registeredAddress $ } +
			%{destinationIndicator $ preferredDeliveryMethod $ telexNumber $ } +
			%{teletexTerminalIdentifier $ telephoneNumber $ internationaliSDNNumber $ } +
			%{facsimileTelephoneNumber $ street $ postOfficeBox $ postalCode $ postalAddress $ } +
			%{physicalDeliveryOfficeName $ st $ l $ description ) )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, OU_OBJECTCLASS )
		end

		it "is a StructuralObjectClass because its kind is 'STRUCTURAL'" do
			@oc.should be_an_instance_of( Treequel::Schema::StructuralObjectClass )
		end

		it "knows what OID corresponds to the class" do
			@oc.oid.should == '2.5.6.5'
		end

		it "knows what its NAME attribute is" do
			@oc.name.should == :organizationalUnit
		end

		it "knows what its DESC attribute is" do
			@oc.desc.should == 'RFC2256: an organizational unit'
		end

		it "knows that it has one MUST attribute" do
			@oc.must_oids.should have( 1 ).member
			@oc.must_oids.should == [ :ou ]
		end

		it "knows what its MAY attributes are" do
			@oc.may_oids.should have( 21 ).members
        	@oc.may_oids.should include( :userPassword, :searchGuide, :seeAlso, :businessCategory,
	        	:x121Address, :registeredAddress, :destinationIndicator, :preferredDeliveryMethod,
	        	:telexNumber, :teletexTerminalIdentifier, :telephoneNumber, :internationaliSDNNumber,
	        	:facsimileTelephoneNumber, :street, :postOfficeBox, :postalCode, :postalAddress,
	        	:physicalDeliveryOfficeName, :st, :l, :description )
		end

	end


	describe "parsed from an objectClass that doesn't specify an explicit KIND attribute" do

		KINDLESS_OBJECTCLASS = %{( 1.1.1.1 )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, KINDLESS_OBJECTCLASS )
		end

		it "is the default kind (STRUCTURAL)" do
			@oc.should be_an_instance_of( Treequel::Schema::StructuralObjectClass )
		end

	end

	describe "parsed from an objectClass that has a list as the value of its NAME attribute" do

		MULTINAME_OBJECTCLASS = %{( 1.1.1.1 NAME ('firstname' 'secondname') )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, MULTINAME_OBJECTCLASS )
		end

		it "knows what both names are" do
			@oc.names.should have(2).members
			@oc.names.should include( :firstname, :secondname )
		end

		it "returns the first of its names for the #name method" do
			@oc.name.should == :firstname
		end

	end

	describe "parsed from an objectClass that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_OBJECTCLASS = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, ESCAPED_DESC_OBJECTCLASS )
		end

		it "unscapes the escaped characters" do
			@oc.desc.should == %{This spec's example, which includes a \\ character.}
		end

	end

	describe "parsed from an objectClass that has the OBSOLETE attribute" do

		OBSOLETE_OBJECTCLASS = %{( 1.1.1.1 OBSOLETE )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, OBSOLETE_OBJECTCLASS )
		end

		it "knows that it's obsolete" do
			@oc.should be_obsolete()
		end

	end

	describe "parsed from an objectClass that has organizationalPerson as its SUP" do

		SUB_OBJECTCLASS = %{( 1.1.1.1 SUP organizationalPerson )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, SUB_OBJECTCLASS )
		end

		it "returns the corresponding objectClass from its schema" do
			@schema.should_receive( :object_classes ).
				and_return({ :organizationalPerson => :organizationalPerson_objectclass })
			@oc.sup.should == :organizationalPerson_objectclass
		end

	end

	describe "parsed from an objectClass that has no explicit SUP" do

		ORPHAN_OBJECTCLASS = %{( 1.1.1.1 )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, ORPHAN_OBJECTCLASS )
		end

		it "returns the objectClass for 'top' from its schema" do
			@schema.should_receive( :object_classes ).
				and_return({ :top => :top_objectclass })
			@oc.sup.should == :top_objectclass
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

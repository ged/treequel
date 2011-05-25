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
require 'treequel/schema/objectclass'
require 'treequel/schema/attributetype'

include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::ObjectClass do
	include Treequel::SpecHelpers

	TOP_OBJECTCLASS =
		%{( 2.5.6.0 NAME 'top' } +
		%{DESC 'top of the superclass chain' ABSTRACT } +
		%{MUST objectClass )}

	PERSON_OBJECTCLASS =
		%{( 2.5.6.6 NAME 'person'} +
		%{    DESC 'RFC2256: a person'} +
		%{    SUP top STRUCTURAL} +
		%{    MUST ( sn $ cn )} +
		%{    MAY ( userPassword $ telephoneNumber $ seeAlso $ description ) )}

	ORGPERSON_OBJECTCLASS =
		%{( 2.5.6.7 NAME 'organizationalPerson'} +
		%{    DESC 'RFC2256: an organizational person'} +
		%{    SUP person STRUCTURAL} +
		%{    MAY ( title $ x121Address $ registeredAddress $ destinationIndicator $} +
		%{        preferredDeliveryMethod $ telexNumber $ teletexTerminalIdentifier $} +
		%{        telephoneNumber $ internationaliSDNNumber $ } +
		%{        facsimileTelephoneNumber $ street $ postOfficeBox $ postalCode $} +
		%{        postalAddress $ physicalDeliveryOfficeName $ ou $ st $ l ) )}

	before( :all ) do
		setup_logging( :fatal )
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		octable = {}
		@schema = stub( "Treequel schema", :object_classes => octable )
		octable[:top] = Treequel::Schema::ObjectClass.parse( @schema, TOP_OBJECTCLASS )
		octable[:person] = Treequel::Schema::ObjectClass.parse( @schema, PERSON_OBJECTCLASS )
		octable[:orgPerson] = Treequel::Schema::ObjectClass.parse( @schema, ORGPERSON_OBJECTCLASS )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'top' objectClass" do

		before( :each ) do
			@oc = @schema.object_classes[:top]
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

		it "can remake its own schema description" do
			@oc.to_s.should == TOP_OBJECTCLASS
		end
	end


	describe "parsed from the 'organizationalPerson' objectClass" do

		before( :each ) do
			@oc = @schema.object_classes[:orgPerson]
		end

		it "is a StructuralObjectClass because its kind is 'STRUCTURAL'" do
			@oc.should be_an_instance_of( Treequel::Schema::StructuralObjectClass )
		end

		it "knows what OID corresponds to the class" do
			@oc.oid.should == '2.5.6.7'
		end

		it "knows what its NAME attribute is" do
			@oc.name.should == :organizationalPerson
		end

		it "knows what its DESC attribute is" do
			@oc.desc.should == 'RFC2256: an organizational person'
		end

		it "knows what its MUST attributes are" do
			@oc.must_oids.should have( 3 ).members
			@oc.must_oids.should include( :sn, :cn, :objectClass )
		end

		it "knows what its unique MUST attributes are" do
			@oc.must_oids( false ).should be_empty()
		end

		it "knows what its MAY attributes are" do
			@oc.may_oids.should have( 22 ).members
        	@oc.may_oids.should include(
				:userPassword, :telephoneNumber, :seeAlso, :description,
				:title, :x121Address, :registeredAddress, :destinationIndicator,
				:preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber,
				:street, :postOfficeBox, :postalCode, :postalAddress,
				:physicalDeliveryOfficeName, :ou, :st, :l )
		end

		it "knows what its unique MAY attributes are" do
			@oc.may_oids( false ).should have( 18 ).members
        	@oc.may_oids( false ).should include(
				:title, :x121Address, :registeredAddress, :destinationIndicator,
				:preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber,
				:street, :postOfficeBox, :postalCode, :postalAddress,
				:physicalDeliveryOfficeName, :ou, :st, :l )
		end

		it "can remake its own schema description" do
			@oc.to_s.should == ORGPERSON_OBJECTCLASS.squeeze(' ')
		end

		it "can fetch all of its ancestors" do
			@oc.ancestors.should == @schema.object_classes.values_at( :orgPerson, :person, :top )
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

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == KINDLESS_OBJECTCLASS
		end
	end

	describe "parsed from an objectClass that has a list as the value of its NAME attribute" do

		MULTINAME_OBJECTCLASS = %{( 1.1.1.1 NAME ( 'firstname' 'secondname' ) )}

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

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == MULTINAME_OBJECTCLASS
		end
	end

	describe "parsed from an objectClass that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_OBJECTCLASS = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, ESCAPED_DESC_OBJECTCLASS )
		end

		it "unescapes the escaped characters" do
			@oc.desc.should == %{This spec's example, which includes a \\ character.}
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == ESCAPED_DESC_OBJECTCLASS
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

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == OBSOLETE_OBJECTCLASS
		end
	end

	describe "parsed from an objectClass that has organizationalPerson as its SUP" do

		SUB_OBJECTCLASS = %{( 1.1.1.1 SUP organizationalPerson )}

		before( :each ) do
			@top = Treequel::Schema::ObjectClass.parse( @schema, TOP_OBJECTCLASS )
			@op = Treequel::Schema::ObjectClass.parse( @schema, ORGPERSON_OBJECTCLASS )
			@oc = Treequel::Schema::ObjectClass.parse( @schema, SUB_OBJECTCLASS )
		end

		it "returns the corresponding objectClass from its schema" do
			@schema.should_receive( :object_classes ).
				and_return({ :organizationalPerson => :organizationalPerson_objectclass })
			@oc.sup.should == :organizationalPerson_objectclass
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == SUB_OBJECTCLASS
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

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			@oc.to_s.sub( / STRUCTURAL/, '' ).should == ORPHAN_OBJECTCLASS
		end
	end


	# Sun/Oracle OpenDS (as of 2.2, at least) "allows a non-numeric OID [as the 
	# 'numericoid' part of an objectClass definition] for the purpose of convenience"
	describe "Sun OpenDS compatibility workarounds (ticket #11)" do

		SUN_ODS_DESCR_OID_OBJECTCLASS = 
			%{( interwovengroup-oid NAME 'interwovengroup' SUP posixgroup } +
			%{    STRUCTURAL MAY path X-ORIGIN 'user defined' )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, SUN_ODS_DESCR_OID_OBJECTCLASS )
		end


		it "sets the oid to the non-numeric OID value" do
			@oc.oid.should == 'interwovengroup-oid'
			@oc.name.should == :interwovengroup
			@oc.extensions.should == %{X-ORIGIN 'user defined'}
		end

	end


	describe "compatibility with malformed declarations: " do

		SLP_SERVICE_OBJECTCLASS = %{
		( 1.3.6.1.4.1.6252.2.27.6.2.1
			NAME 'slpService'
			DESC 'parent superclass for SLP services'
			ABSTRACT
			SUP top
			MUST  ( template-major-version-number $
			        template-minor-version-number $
			        description $
			        template-url-syntax $
			        service-advert-service-type $
			        service-advert-scopes )
			MAY   ( service-advert-url-authenticator $
			        service-advert-attribute-authenticator ) )
		}

		it "parses the malformed objectClass from RFC 2926" do
			oc = Treequel::Schema::ObjectClass.parse( @schema, SLP_SERVICE_OBJECTCLASS )

			oc.should be_a( Treequel::Schema::ObjectClass )
			oc.name.should == :slpService
			oc.oid.should == '1.3.6.1.4.1.6252.2.27.6.2.1'
		end


		AUTH_PASSWORD_OBJECT_OBJECTCLASS = %{
		( 1.3.6.1.4.1.4203.1.4.7 NAME 'authPasswordObject'
			DESC 'authentication password mix in class'
			MAY 'authPassword'
			AUXILIARY )
		}

		it "parses the malformed authPasswordObject objectClass from RFC2696" do
			oc = Treequel::Schema::ObjectClass.parse( @schema, AUTH_PASSWORD_OBJECT_OBJECTCLASS )

			oc.should be_a( Treequel::Schema::ObjectClass )
			oc.name.should == :authPasswordObject
			oc.oid.should == '1.3.6.1.4.1.4203.1.4.7'
		end

		DRAFT_HOWARD_RFC2307BIS_OBJECTCLASS = %{
		( 1.3.6.1.1.1.2.0 NAME 'posixAccount' 
			SUP top 
			AUXILIARY 
			DESC 'Abstraction of an account with POSIX attributes' 
			MUST ( cn $ uid $ uidNumber $ gidNumber $ homeDirectory ) 
			MAY ( authPassword $ userPassword $ loginShell $ gecos $ description ) 
			X-ORIGIN 'draft-howard-rfc2307bis' )
		}

		it "parses the malformed objectClasses from draft-howard-rfc2307bis" do
			oc = Treequel::Schema::ObjectClass.parse( @schema, DRAFT_HOWARD_RFC2307BIS_OBJECTCLASS )

			oc.should be_a( Treequel::Schema::ObjectClass )
			oc.name.should == :posixAccount
			oc.oid.should == '1.3.6.1.1.1.2.0'
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

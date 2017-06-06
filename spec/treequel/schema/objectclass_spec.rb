#!/usr/bin/env ruby

require_relative '../../spec_helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/objectclass'
require 'treequel/schema/attributetype'

include Treequel::SpecConstants
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
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		octable = {}
		@schema = double( "Treequel schema", :object_classes => octable )
		octable[:top] = Treequel::Schema::ObjectClass.parse( @schema, TOP_OBJECTCLASS )
		octable[:person] = Treequel::Schema::ObjectClass.parse( @schema, PERSON_OBJECTCLASS )
		octable[:orgPerson] = Treequel::Schema::ObjectClass.parse( @schema, ORGPERSON_OBJECTCLASS )
	end


	describe "parsed from the 'top' objectClass" do

		before( :each ) do
			@oc = @schema.object_classes[:top]
		end

		it "is an AbstractObjectClass because its 'kind' is 'ABSTRACT'" do
			expect( @oc ).to be_an_instance_of( Treequel::Schema::AbstractObjectClass )
		end

		it "knows what OID corresponds to the class" do
			expect( @oc.oid ).to eq( '2.5.6.0' )
		end

		it "knows what its NAME attribute is" do
			expect( @oc.name ).to eq( :top )
		end

		it "knows what its DESC attribute is" do
			expect( @oc.desc ).to eq( 'top of the superclass chain' )
		end

		it "knows that it has one MUST attribute" do
			expect( @oc.must_oids.length ).to eq( 1 )
			expect( @oc.must_oids ).to eq( [ :objectClass ] )
		end

		it "returns attribute objects for its MUST OIDs" do
			expect( @schema ).to receive( :attribute_types ).at_least( :once ).
				and_return({ :objectClass => :attribute_type })

			expect( @oc.must.length ).to eq( 1 )
			expect( @oc.must ).to eq( [ :attribute_type ] )
		end

		it "returns attribute objects for its MAY OIDs" do
			expect( @schema ).to receive( :attribute_types ).at_least( :once ).
				and_return({ :objectClass => :attribute_type })

			expect( @oc.must.length ).to eq( 1 )
			expect( @oc.must ).to eq( [ :attribute_type ] )
		end

		it "knows that it doesn't have any MAY attributes" do
			expect( @oc.may_oids ).to be_empty()
		end

		it "knows that it is not obsolete" do
			expect( @oc ).to_not be_obsolete()
		end

		it "knows that it doesn't have a superclass" do
			expect( @oc.sup ).to be_nil()
		end

		it "can remake its own schema description" do
			expect( @oc.to_s ).to eq( TOP_OBJECTCLASS )
		end
	end


	describe "parsed from the 'organizationalPerson' objectClass" do

		before( :each ) do
			@oc = @schema.object_classes[:orgPerson]
		end

		it "is a StructuralObjectClass because its kind is 'STRUCTURAL'" do
			expect( @oc ).to be_an_instance_of( Treequel::Schema::StructuralObjectClass )
		end

		it "knows what OID corresponds to the class" do
			expect( @oc.oid ).to eq( '2.5.6.7' )
		end

		it "knows what its NAME attribute is" do
			expect( @oc.name ).to eq( :organizationalPerson )
		end

		it "knows what its DESC attribute is" do
			expect( @oc.desc ).to eq( 'RFC2256: an organizational person' )
		end

		it "knows what its MUST attributes are" do
			expect( @oc.must_oids.length ).to eq( 3 )
			expect( @oc.must_oids ).to include( :sn, :cn, :objectClass )
		end

		it "knows what its unique MUST attributes are" do
			expect( @oc.must_oids( false ) ).to be_empty()
		end

		it "knows what its MAY attributes are" do
			expect( @oc.may_oids.length ).to eq( 22 )
			expect( @oc.may_oids ).to include(
				:userPassword, :telephoneNumber, :seeAlso, :description,
				:title, :x121Address, :registeredAddress, :destinationIndicator,
				:preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber,
				:street, :postOfficeBox, :postalCode, :postalAddress,
				:physicalDeliveryOfficeName, :ou, :st, :l
			)
		end

		it "knows what its unique MAY attributes are" do
			expect( @oc.may_oids(false).length ).to eq( 18 )
			expect( @oc.may_oids(false) ).to include(
				:title, :x121Address, :registeredAddress, :destinationIndicator,
				:preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber,
				:street, :postOfficeBox, :postalCode, :postalAddress,
				:physicalDeliveryOfficeName, :ou, :st, :l
			)
		end

		it "can remake its own schema description" do
			expect( @oc.to_s ).to eq( ORGPERSON_OBJECTCLASS.squeeze(' ') )
		end

		it "can fetch all of its ancestors" do
			expect( @oc.ancestors ).to eq( @schema.object_classes.values_at( :orgPerson, :person, :top ) )
		end
	end


	describe "parsed from an objectClass that doesn't specify an explicit KIND attribute" do

		KINDLESS_OBJECTCLASS = %{( 1.1.1.1 )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, KINDLESS_OBJECTCLASS )
		end

		it "is the default kind (STRUCTURAL)" do
			expect( @oc ).to be_an_instance_of( Treequel::Schema::StructuralObjectClass )
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( KINDLESS_OBJECTCLASS )
		end
	end

	describe "parsed from an objectClass that has a list as the value of its NAME attribute" do

		MULTINAME_OBJECTCLASS = %{( 1.1.1.1 NAME ( 'firstname' 'secondname' ) )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, MULTINAME_OBJECTCLASS )
		end

		it "knows what both names are" do
			expect( @oc.names.length ).to eq( 2 )
			expect( @oc.names ).to include( :firstname, :secondname )
		end

		it "returns the first of its names for the #name method" do
			expect( @oc.name ).to eq( :firstname )
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( MULTINAME_OBJECTCLASS )
		end
	end

	describe "parsed from an objectClass that has escaped characters in its DESC attribute" do

		ESCAPED_DESC_OBJECTCLASS = %{( 1.1.1.1 DESC } +
			%{'This spec\\27s example, which includes a \\5c character.' )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, ESCAPED_DESC_OBJECTCLASS )
		end

		it "unescapes the escaped characters" do
			expect( @oc.desc ).to eq( %{This spec's example, which includes a \\ character.} )
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( ESCAPED_DESC_OBJECTCLASS )
		end
	end

	describe "parsed from an objectClass that has the OBSOLETE attribute" do

		OBSOLETE_OBJECTCLASS = %{( 1.1.1.1 OBSOLETE )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, OBSOLETE_OBJECTCLASS )
		end

		it "knows that it's obsolete" do
			expect( @oc ).to be_obsolete()
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( OBSOLETE_OBJECTCLASS )
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
			expect( @schema ).to receive( :object_classes ).
				and_return({ :organizationalPerson => :organizationalPerson_objectclass })
			expect( @oc.sup ).to eq( :organizationalPerson_objectclass )
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( SUB_OBJECTCLASS )
		end

	end

	describe "parsed from an objectClass that has no explicit SUP" do

		ORPHAN_OBJECTCLASS = %{( 1.1.1.1 )}

		before( :each ) do
			@oc = Treequel::Schema::ObjectClass.parse( @schema, ORPHAN_OBJECTCLASS )
		end

		it "returns the objectClass for 'top' from its schema" do
			expect( @schema ).to receive( :object_classes ).
				and_return({ :top => :top_objectclass })
			expect( @oc.sup ).to eq( :top_objectclass )
		end

		it "can remake its own schema description" do
			# STRUCTURAL is implied...
			expect( @oc.to_s.sub( / STRUCTURAL/, '' ) ).to eq( ORPHAN_OBJECTCLASS )
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
			expect( @oc.oid ).to eq( 'interwovengroup-oid' )
			expect( @oc.name ).to eq( :interwovengroup )
			expect( @oc.extensions ).to eq( %{X-ORIGIN 'user defined'} )
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

			expect( oc ).to be_a( Treequel::Schema::ObjectClass )
			expect( oc.name ).to eq( :slpService )
			expect( oc.oid ).to eq( '1.3.6.1.4.1.6252.2.27.6.2.1' )
		end


		AUTH_PASSWORD_OBJECT_OBJECTCLASS = %{
		( 1.3.6.1.4.1.4203.1.4.7 NAME 'authPasswordObject'
			DESC 'authentication password mix in class'
			MAY 'authPassword'
			AUXILIARY )
		}

		it "parses the malformed authPasswordObject objectClass from RFC2696" do
			oc = Treequel::Schema::ObjectClass.parse( @schema, AUTH_PASSWORD_OBJECT_OBJECTCLASS )

			expect( oc ).to be_a( Treequel::Schema::ObjectClass )
			expect( oc.name ).to eq( :authPasswordObject )
			expect( oc.oid ).to eq( '1.3.6.1.4.1.4203.1.4.7' )
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

			expect( oc ).to be_a( Treequel::Schema::ObjectClass )
			expect( oc.name ).to eq( :posixAccount )
			expect( oc.oid ).to eq( '1.3.6.1.1.1.2.0' )
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

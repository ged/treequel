# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'treequel/model'
require 'treequel/model/schemavalidations'


describe Treequel::Model::SchemaValidations do

	before( :each ) do
		@conn = double( "LDAP connection", :bound? => false )
		@directory = get_fixtured_directory( @conn )
		@modelobj = Treequel::Model.new( @directory, TEST_PERSON_DN )
	end

	# StructuralObjectClass ( 2.5.6.6 NAME 'person'
	#	DESC 'RFC2256: a person'
	# 	SUP top STRUCTURAL
	# 	MUST ( sn $ cn )
	# 	MAY ( userPassword $ telephoneNumber $ seeAlso $ description ) )

	it "adds an error if the object doesn't have at least one structural objectClass" do
		expect( @conn ).to receive( :search_ext2 ).at_least( :once ).and_return( [] )
		@modelobj.object_class = :posixAccount
		@modelobj.cn = 'jrandom'
		@modelobj.uid_number = 2881
		@modelobj.gid_number = 761
		@modelobj.home_directory = '/home/jrandom'

		expect( @modelobj ).to_not be_valid()
		expect( @modelobj.errors.length ).to eq( 1 )
		expect( @modelobj.errors.full_messages ).
			to include( 'entry must have at least one structural objectClass' )
	end

	it "adds an error if the object doesn't have at least one value for all of its MUST attributes" do
		expect( @conn ).to receive( :search_ext2 ).at_least( :once ).and_return( [] )
		@modelobj.object_class = [:person, :uidObject]

		expect( @modelobj ).to_not be_valid()
		expect( @modelobj.errors.length ).to eq( 2 )
		expect( @modelobj.errors.full_messages ).to include( 'cn MUST have at least one value' )
		expect( @modelobj.errors.full_messages ).to include( 'sn MUST have at least one value' )
	end

	it "adds an error if the object has a value for an attribute that isn't in one of its MAY attributes" do
		expect( @conn ).to receive( :search_ext2 ).and_return([ TEST_PERSON_ENTRY.dup ])

		# ..then remove the objectclass that grants it and validate
		@modelobj.object_class -= ['inetOrgPerson']
		expect( @modelobj ).to_not be_valid()

		expect( @modelobj.errors.full_messages ).
			to include( "displayName is not allowed by entry's objectClasses" )
	end

	it "doesn't add errors for operational attributes" do
		expect( @conn ).to receive( :search_ext2 ).and_return([ TEST_OPERATIONAL_PERSON_ENTRY.dup ])
		@modelobj.l = ['Birmingham']
		@modelobj.validate
		# expect( @modelobj.operational_attribute_oids ).to eq( [] )
		# expect( @modelobj ).to be_valid()
		expect( @modelobj.errors.full_messages ).to eq( [] )
	end


	# AuxiliaryObjectClass ( 1.3.6.1.1.1.2.0 NAME 'posixAccount'
	# 	DESC 'Abstraction of an account with POSIX attributes'
	# 	SUP top AUXILIARY
	# 	MUST ( cn $ uid $ uidNumber $ gidNumber $ homeDirectory )
	# 	MAY ( userPassword $ loginShell $ gecos $ description ) )

	it "adds an error if the object has a value for an attribute that doesn't match the " +
	   "attribute's syntax" do
		expect( @conn ).to receive( :search_ext2 ).at_least( :once ).and_return( [] )

		@modelobj.object_class = ['inetOrgPerson', 'posixAccount']
		@modelobj.cn = 'J. Random'
		@modelobj.sn = 'Hacker'
		@modelobj.uid = 'jrandom'
		@modelobj.home_directory = '/users/j/jrandom'

		# Set the 'Integer' attributes to values that can't be cast to integers
		@modelobj.uid_number = "something that's not a number"
		@modelobj.gid_number = "also not a number"

		expect( @modelobj ).to_not be_valid()

		expect( @modelobj.errors.length ).to eq( 2 )
		expect( @modelobj.errors.full_messages ).to include( "uidNumber isn't a valid Integer value" )
		expect( @modelobj.errors.full_messages ).to include( "gidNumber isn't a valid Integer value" )
	end

	it "does nothing if :with_schema => false is passed to #validate" do
		expect( @conn ).to receive( :search_ext2 ).at_least( :once ).and_return( [] )
		@modelobj.object_class = 'person' # MUST ( sn $ cn )
		@modelobj.validate( :with_schema => false )
		expect( @modelobj.errors ).to be_empty()
	end

end


# vim: set nosta noet ts=4 sw=4:

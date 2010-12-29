#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'treequel/model'
require 'treequel/model/schemavalidations'



#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Model::SchemaValidations do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@conn = double( "LDAP connection", :bound? => false )
		@directory = get_fixtured_directory( @conn )
		@modelobj = Treequel::Model.new( @directory, TEST_PERSON_DN )
	end

	after( :all ) do
		reset_logging()
	end

	# StructuralObjectClass ( 2.5.6.6 NAME 'person' 
	#	DESC 'RFC2256: a person' 
	# 	SUP top STRUCTURAL 
	# 	MUST ( sn $ cn ) 
	# 	MAY ( userPassword $ telephoneNumber $ seeAlso $ description ) )

	it "adds an error if the object doesn't have at least one value for all of its MUST attributes" do
		@conn.stub( :search_ext2 ).and_return( [] )
		@modelobj.object_class = 'person'
		@modelobj.validate
		@modelobj.errors.should have( 2 ).members
		@modelobj.errors.full_messages.should include( 'cn MUST have at least one value' )
		@modelobj.errors.full_messages.should include( 'sn MUST have at least one value' )
	end

	it "adds an error if the object has a value for an attribute that isn't in one of its MAY attributes" do
		# First set the object classes to include one which MAY have a 'displayName'
		entry = {
			'objectClass' => ['person', 'inetOrgPerson'],
			'cn'          => ['J. Random'],
			'sn'          => ['Hacker'],
			'displayName' => ['Trinket the Trivial']
		}
		@conn.stub( :search_ext2 ).and_return([ entry ])

		# ..then remove the objectclass that grants it and validate
		@modelobj.object_class -= ['inetOrgPerson']
		@modelobj.validate

		@modelobj.errors.full_messages.
			should == [%{displayName is not allowed by entry's objectClasses}]
	end

	# AuxiliaryObjectClass ( 1.3.6.1.1.1.2.0 NAME 'posixAccount' 
	# 	DESC 'Abstraction of an account with POSIX attributes' 
	# 	SUP top AUXILIARY 
	# 	MUST ( cn $ uid $ uidNumber $ gidNumber $ homeDirectory ) 
	# 	MAY ( userPassword $ loginShell $ gecos $ description ) )

	it "adds an error if the object has a value for an attribute that doesn't match the " +
	   "attribute's syntax" do
		@conn.stub( :search_ext2 ).and_return( [] )

		@modelobj.object_class = ['inetOrgPerson', 'posixAccount']
		@modelobj.cn = 'J. Random'
		@modelobj.sn = 'Hacker'
		@modelobj.uid = 'jrandom'
		@modelobj.home_directory = '/users/j/jrandom'

		# Set the 'Integer' attributes to values that can't be cast to integers
		@modelobj.uid_number = "something that's not a number"
		@modelobj.gid_number = "also not a number"

		@modelobj.validate

		@modelobj.errors.should have( 2 ).members
		@modelobj.errors.full_messages.should include( "uidNumber isn't a valid Integer value" )
		@modelobj.errors.full_messages.should include( "gidNumber isn't a valid Integer value" )
	end

	it "does nothing if :with_schema => false is passed to #validate" do
		@conn.stub( :search_ext2 ).and_return( [] )
		@modelobj.object_class = 'person' # MUST ( sn $ cn )
		@modelobj.validate( :with_schema => false )
		@modelobj.errors.should be_empty()
	end

end


# vim: set nosta noet ts=4 sw=4:

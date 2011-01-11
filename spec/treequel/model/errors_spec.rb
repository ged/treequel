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
require 'treequel/model/errors'
require 'treequel/branchset'



#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Model::Errors do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@errors = Treequel::Model::Errors.new
	end

	after( :all ) do
		reset_logging()
	end


	it "allows the addition of errors" do
		@errors.add( :cn, "Not a common name." )
		@errors[:cn].should have( 1 ).member
		@errors[:cn].should include( "Not a common name." )
	end

	it "knows how many errors there are" do
		@errors.add( :l, "is not valid" )
		@errors.add( :description, "must be this tall to ride" )
		@errors.add( :description, "must have at least one value" )

		@errors.count.should == 3
	end

	it "is empty if there haven't been any errors registered" do
		@errors.should be_empty()
	end

	it "isn't empty if there have been errors registered" do
		@errors.add( :uid, 'duplicate value' )
		@errors.should_not be_empty()
	end

	it "can build an array of error messages" do
		@errors.add( :l, "is not a valid location" )
		@errors.add( [:givenName, :sn, :displayName], "must be unique" )

		@errors.full_messages.should have( 2 ).members
		@errors.full_messages.should include( "givenName and sn and displayName must be unique" )
		@errors.full_messages.should include( "l is not a valid location" )
	end

end


# vim: set nosta noet ts=4 sw=4:

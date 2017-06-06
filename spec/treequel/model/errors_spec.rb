# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'treequel/model'
require 'treequel/model/errors'
require 'treequel/branchset'


describe Treequel::Model::Errors do

	before( :each ) do
		@errors = Treequel::Model::Errors.new
	end


	it "allows the addition of errors" do
		@errors.add( :cn, "Not a common name." )
		expect( @errors[:cn].length ).to eq( 1 )
		expect( @errors[:cn] ).to include( "Not a common name." )
	end

	it "knows how many errors there are" do
		@errors.add( :l, "is not valid" )
		@errors.add( :description, "must be this tall to ride" )
		@errors.add( :description, "must have at least one value" )

		expect( @errors.count ).to eq( 3 )
	end

	it "is empty if there haven't been any errors registered" do
		expect( @errors ).to be_empty()
	end

	it "isn't empty if there have been errors registered" do
		@errors.add( :uid, 'duplicate value' )
		expect( @errors ).to_not be_empty()
	end

	it "can build an array of error messages" do
		@errors.add( :l, "is not a valid location" )
		@errors.add( [:givenName, :sn, :displayName], "must be unique" )

		expect( @errors.full_messages.length ).to eq( 2 )
		expect( @errors.full_messages ).to include( "givenName and sn and displayName must be unique" )
		expect( @errors.full_messages ).to include( "l is not a valid location" )
	end

end


# vim: set nosta noet ts=4 sw=4:

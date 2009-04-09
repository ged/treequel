#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel/branchset'
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

describe Treequel::BranchSet do
	include Treequel::SpecHelpers
	
	before( :all ) do
		setup_logging( :fatal )
	end
	
	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@directory = mock( "treequel directory ")
		@branch = mock( "treequel branchset" )
	end


	it "can be created with an initial 'filter' option" do
		branchset = Treequel::BranchSet.new( @branch, :filter => [:uid, 'redhouse'] )
		branchset.options[:filter].should == [:uid, 'redhouse']
	end
	

	describe "an instance with no options set" do

		before( :each ) do
			@branchset = Treequel::BranchSet.new( @branch )
		end
		

		it "returns an Array of all Branches immediately beneath itself with if no other criteria are specified" do
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::BranchSet::DEFAULT_SCOPE, /(objectClass=*)/ ).
				and_return( :matching_branches )
			
			@branchset.all.should == :matching_branches
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

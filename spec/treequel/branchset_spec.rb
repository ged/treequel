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
		setup_logging( :debug )
	end
	
	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		pending "finishing filter work"
		@directory = mock( "treequel directory ")
		@branch = mock( "treequel branchset" )
	end


	describe "an instance with no filter, options, or scope set" do

		before( :each ) do
			@branchset = Treequel::BranchSet.new( @branch )
		end
		

		it "generates a valid filter string" do
			pending do
				@branchset.filter_string.should == '(objectClass=*)'
			end
		end
	

		it "performs a search using the default filter and scope when all records are requested" do
			pending do
				@branch.should_receive( :directory ).and_return( @directory )
				@directory.should_receive( :search ).
					with( @branch, Treequel::BranchSet::DEFAULT_SCOPE, /(objectClass=*)/ ).
					and_return( :matching_branches )
			
				@branchset.all.should == :matching_branches
			end
		end

		it "creates a new branchset with the specified filter" do
			pending do
				newset = @branchset.filter( :clothing => 'pants' )
				newset.should_not equal( @branchset )
				newset.options.should_not equal( @branchset.options )
				newset.filter_string.should == '(clothing=pants)'
			end
		end
		

	end

	describe "an instance with no filter, and scope set to 'onelevel'" do

		before( :each ) do
			@branchset = Treequel::BranchSet.new( @branch, :scope => :onelevel )
		end
		

		it "generates a valid filter string" do
			pending do
				@branchset.filter_string.should == '(objectClass=*)'
			end
		end
	

		it "performs a search using the default filter and scope when all records are requested" do
			pending do
				@branch.should_receive( :directory ).and_return( @directory )
				@directory.should_receive( :search ).
					with( @branch, :onelevel, /(objectClass=*)/ ).
					and_return( :matching_branches )
			
				@branchset.all.should == :matching_branches
			end
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

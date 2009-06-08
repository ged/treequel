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

describe Treequel::Branchset do
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


	describe "an instance with no filter, options, or scope set" do

		before( :each ) do
			@branchset = Treequel::Branchset.new( @branch )
		end

		it "can clone itself with merged options" do
			newset = @branchset.clone( :scope => :one )
			newset.should be_a( Treequel::Branchset )
			newset.should_not equal( @branchset )
			newset.options.should_not equal( @branchset.options )
			newset.scope.should == :one
		end


		# 
		# #filter
		# 

		it "generates a valid filter string" do
			@branchset.filter_string.should == '(objectClass=*)'
		end


		it "performs a search using the default filter and scope when all records are requested" do
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, [], 0, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

		it "performs a search using the default filter and scope when the first record is requested" do
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, [], 0, '' ).
				and_return( [:first_matching_branch, :other_branches] )

			@branchset.first.should == :first_matching_branch
		end

		it "creates a new branchset cloned from itself with the specified filter" do
			newset = @branchset.filter( :clothing, 'pants' )
			newset.filter_string.should == '(clothing=pants)'
		end

		# 
		# #scope
		# 

		it "provides a reader for its scope" do
			@branchset.scope.should == :subtree
		end

		it "can create a new branchset cloned from itself with a different scope" do
			newset = @branchset.scope( :onelevel )
			newset.should be_a( Treequel::Branchset )
			newset.should_not equal( @branchset )
			newset.options.should_not equal( @branchset.options )
			newset.scope.should == :onelevel
		end

		it "can create a new branchset cloned from itself with a different string scope" do
			newset = @branchset.scope( 'sub' )
			newset.scope.should == :sub
		end

		it "uses its scope setting as the scope to use when searching" do
			@branchset.options[:scope] = :onelevel
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, :onelevel, @branchset.filter, [], 0, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

		# 
		# #select
		# 
		it "can create a new branchset cloned from itself with an attribute selection" do
			newset = @branchset.select( :l, :lastName, :disabled )
			newset.select.should == [ 'l', 'lastName', 'disabled' ]
		end

		it "can create a new branchset cloned from itself with all attributes selected" do
			newset = @branchset.select_all
			newset.select.should == []
		end

		it "can create a new branchset cloned from itself with additional attributes selected" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			newset = @branchset.select_more( :firstName, :uid, :lastName )
			newset.select.should == [ 'l', 'cn', 'uid', 'firstName', 'lastName' ]
		end

		it "uses its selection as the list of attributes to fetch when searching" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, 
				      ['l', 'cn', 'uid'], 0, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

		# 
		# #timeout
		# 

		it "can create a new branchset cloned from itself with a timeout" do
			newset = @branchset.timeout( 30 )
			newset.timeout.should == 30.0
		end

		it "can create a new branchset cloned from itself without a timeout" do
			@branchset.options[:timeout] = 5.375
			newset = @branchset.without_timeout
			newset.timeout.should == 0
		end

		it "uses its timeout as the timeout values when searching" do
			@branchset.options[:timeout] = 5.375
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, 
				      [], 5.375, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

		# 
		# #order
		# 

		it "can create a new branchset cloned from itself with a sort-order attribute" do
			newset = @branchset.order( :uid )
			newset.order.should == :uid
		end

		it "converts a string sort-order attribute to a Symbol" do
			newset = @branchset.order( 'uid' )
			newset.order.should == :uid
		end

		it "can set a sorting function instead of an attribute" do
			newset = @branchset.order {|branch| branch.uid }
			newset.order.should be_a( Proc )
		end

		it "can create a new branchset cloned from itself without a sort-order attribute" do
			@branchset.options[:order] = :uid
			newset = @branchset.order( nil )
			newset.order.should == nil
		end

		it "uses its timeout as the timeout values when searching" do
			@branchset.options[:timeout] = 5.375
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, 
				      [], 5.375, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

	end

	describe "an instance with no filter, and scope set to 'onelevel'" do

		before( :each ) do
			@branchset = Treequel::Branchset.new( @branch, :scope => :onelevel )
		end


		it "generates a valid filter string" do
			@branchset.filter_string.should == '(objectClass=*)'
		end


		it "performs a search using the default filter and scope when all records are requested" do
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, :onelevel, @branchset.filter, [], 0, '' ).
				and_return( :matching_branches )

			@branchset.all.should == :matching_branches
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

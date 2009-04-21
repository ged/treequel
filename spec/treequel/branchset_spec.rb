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
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, /\(objectClass=\*\)/, 
				      nil, false, 0, 0, nil, nil ).
				and_return( :matching_branches )
		
			@branchset.all.should == :matching_branches
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
				with( @branch, :onelevel, /\(objectClass=\*\)/, 
				      nil, false, 0, 0, nil, nil ).
				and_return( :matching_branches )
		
			@branchset.all.should == :matching_branches
		end
		
		# 
		# #select
		# 
		it "can create a new branchset cloned from itself with an attribute selection" do
			newset = @branchset.select( :l, :lastName, :disabled )
			newset.select.should == [ :l, :lastName, :disabled ]
		end
		
		it "can create a new branchset cloned from itself with all attributes selected" do
			newset = @branchset.select_all
			newset.select.should == nil
		end
		
		it "can create a new branchset cloned from itself with additional attributes selected" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			newset = @branchset.select_more( :firstName, :uid, :lastName )
			newset.select.should == [ :l, :cn, :uid, :firstName, :lastName ]
		end

		it "uses its selection as the list of attributes to fetch when searching" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			@branch.should_receive( :directory ).and_return( @directory )
			@directory.should_receive( :search ).
				with( @branch, Treequel::Branchset::DEFAULT_SCOPE, /\(objectClass=\*\)/, 
				      [:l, :cn, :uid], false, 0, 0, nil, nil ).
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

		it "uses its timeout as the timeout values when searching" do
			pending "completion of the timeout code in #search" do
				@branchset.options[:timeout] = 5.375
				@branch.should_receive( :directory ).and_return( @directory )
				@directory.should_receive( :search ).
					with( @branch, Treequel::Branchset::DEFAULT_SCOPE, /\(objectClass=\*\)/, 
					      [:l, :cn, :uid], false, 5, 375_000, nil, nil ).
					and_return( :matching_branches )
		
				@branchset.all.should == :matching_branches
			end
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
				with( @branch, :onelevel, /\(objectClass=\*\)/, 
				      nil, false, 0, 0, nil, nil ).
				and_return( :matching_branches )
		
			@branchset.all.should == :matching_branches
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

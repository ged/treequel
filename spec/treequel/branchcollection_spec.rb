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

	require 'treequel/branchcollection'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::BranchCollection do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :debug )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@directory = mock( "treequel directory ")
	end

	it "can be instantiated without any branchsets" do
		collection = Treequel::BranchCollection.new
		collection.all.should == []
	end

	it "can be instantiated with one or more branchsets" do
		branchset1 = stub( "branchset 1", :dn => 'cn=example1,dc=acme,dc=com', :each => 1 )
		branchset2 = stub( "branchset 2", :dn => 'cn=example2,dc=acme,dc=com', :each => 1 )

		collection = Treequel::BranchCollection.new( branchset1, branchset2 )

		collection.branchsets.should include( branchset1, branchset2 )
	end

	it "wraps any object that doesn't have an #each in a Branchset" do
		non_branchset1 = stub( "non-branchset 1" )
		non_branchset2 = stub( "non-branchset 2" )
		branchset1 = stub( "branchset 1", :dn => 'cn=example1,dc=acme,dc=com' )
		branchset2 = stub( "branchset 2", :dn => 'cn=example2,dc=acme,dc=com' )

		Treequel::Branchset.should_receive( :new ).with( non_branchset1 ).
			and_return( branchset1 )
		Treequel::Branchset.should_receive( :new ).with( non_branchset2 ).
			and_return( branchset2 )

		collection = Treequel::BranchCollection.new( non_branchset1, non_branchset2 )

		collection.branchsets.should include( branchset1, branchset2 )
	end

	it "allows new Branchsets to be appended to it" do
		branchset1 = mock( "branchset 1" )
		branchset2 = mock( "branchset 2" )

		collection = Treequel::BranchCollection.new
		collection << branchset1 << branchset2

		collection.should include( branchset1, branchset2 )
	end

	it "allows new Branches to be appended to it" do
		branch1 = mock( "branch 1", :branchset => :branchset1 )
		branch2 = mock( "branch 2", :branchset => :branchset2 )

		collection = Treequel::BranchCollection.new
		collection << branch1 << branch2

		collection.should include( :branchset1, :branchset2 )
	end


	describe "instance with two Branchsets" do

		before( :each ) do
			@branchset1 = mock( "branchset 1", :dn => 'cn=example1,dc=acme,dc=com', :each => 1 )
			@branchset2 = mock( "branchset 2", :dn => 'cn=example2,dc=acme,dc=com', :each => 1 )

			@collection = Treequel::BranchCollection.new( @branchset1, @branchset2 )
		end

		it "knows that it is empty if all of its branchsets are empty"

		it "fetches all of the results from each of its branchsets if asked for all results" do
			@branchset1.should_receive( :each ).and_yield( :bs1_stuff )
			@branchset2.should_receive( :each ).and_yield( :bs2_stuff )

			@collection.all.should == [ :bs1_stuff, :bs2_stuff ]
		end

		it "fetches the first Branch returned by any of its branchsets when asked" do
			@branchset1.should_receive( :first ).and_return( nil )
			@branchset2.should_receive( :first ).and_return( :a_branch )

			@collection.first.should == :a_branch
		end

		it "returns a clone of itself with an additional Branchset if a Branchset is added to it" do
			branchset3 = mock( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			new_collection = @collection + branchset3

			new_collection.should be_an_instance_of( Treequel::BranchCollection )
			new_collection.should include( @branchset1, @branchset2, branchset3 )
		end

		it "returns a clone of itself with an additional Branchset if a Branch is added to it" do
			branchset3 = mock( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			branch3 = mock( "branch 3", :branchset => branchset3 )
			new_collection = @collection + branch3

			new_collection.should be_an_instance_of( Treequel::BranchCollection )
			new_collection.should include( @branchset1, @branchset2, branchset3 )
		end

		it "returns a clone of itself with both collections' Branchsets if a BranchCollection is " +
		   "added to it" do
			branchset3 = stub( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			branchset4 = stub( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
			other_collection = Treequel::BranchCollection.new( branchset3, branchset4 )

			new_collection = @collection + other_collection

			new_collection.should be_an_instance_of( Treequel::BranchCollection )
			new_collection.should include( @branchset1, @branchset2, branchset3, branchset4 )
		end

		it "returns a new BranchCollection with the union of Branchsets if it is ORed with " +
		   "another BranchCollection" do
			branchset3 = stub( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			branchset4 = stub( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
			other_collection = Treequel::BranchCollection.new( branchset3, branchset4 )

			new_collection = @collection | other_collection

			new_collection.should be_an_instance_of( Treequel::BranchCollection )
			new_collection.should include( @branchset1, @branchset2, branchset3, branchset4 )
		end

		it "returns a new BranchCollection with the intersection of Branchsets if it is ANDed with " +
		   "another BranchCollection" do
			branchset3 = stub( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			branchset4 = stub( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
			other_collection = Treequel::BranchCollection.new( @branchset2, branchset3, branchset4 )
			@collection << branchset4

			new_collection = @collection & other_collection

			new_collection.should be_an_instance_of( Treequel::BranchCollection )
			new_collection.should include( @branchset2, branchset4 )
		end

		it "can create a clone of itself with filtered branchsets" do
			filtered_branchset1 = stub( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
			filtered_branchset2 = stub( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
			@branchset1.should_receive( :filter ).with( :cn => 'chunkalicious' ).
				and_return( filtered_branchset1 )
			@branchset2.should_receive( :filter ).with( :cn => 'chunkalicious' ).
				and_return( filtered_branchset2 )

			filtered_collection = @collection.filter( :cn => 'chunkalicious' )
			filtered_collection.should_not be_equal( @collection )
			filtered_collection.should include( filtered_branchset1, filtered_branchset2 )
		end

		# it "can create a clone of itself with ordered branchsets" do
		# 	ordered_branchset1 = stub( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
		# 	ordered_branchset2 = stub( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
		# 	@branchset1.should_receive( :order ).with( :cn ).
		# 		and_return( ordered_branchset1 )
		# 	@branchset2.should_receive( :order ).with( :cn ).
		# 		and_return( ordered_branchset2 )
		# 
		# 	ordered_collection = @collection.order( :cn )
		# 	ordered_collection.should_not be_equal( @collection )
		# 	ordered_collection.should include( ordered_branchset1, ordered_branchset2 )
		# end
		# 
		it "can return the base DNs of all of its branchsets" do
			@branchset1.should_receive( :base_dn ).and_return( :branchset1_basedn )
			@branchset2.should_receive( :base_dn ).and_return( :branchset2_basedn )
			@collection.base_dns.should == [ :branchset1_basedn, :branchset2_basedn ]
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

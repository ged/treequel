#!/usr/bin/env ruby

require_relative '../spec_helpers'


require 'treequel/branchcollection'


include Treequel::SpecConstants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::BranchCollection do
	include Treequel::SpecHelpers

	before( :each ) do
		@directory = double( "treequel directory", :registered_controls => [] )
	end

	it "can be instantiated without any branchsets" do
		collection = Treequel::BranchCollection.new
		expect( collection.all ).to eq( [] )
	end

	it "can be instantiated with one or more branchsets" do
		branch1 = double( "branch for branchset 1", :directory => @directory )
		branchset1 = Treequel::Branchset.new( branch1 )
		branch2 = double( "branch for branchset 2", :directory => @directory )
		branchset2 = Treequel::Branchset.new( branch2 )

		collection = Treequel::BranchCollection.new( branchset1, branchset2 )

		expect( collection.branchsets ).to include( branchset1, branchset2 )
	end

	it "wraps any object that doesn't have an #each in a Branchset" do
		branch1 = double( "branch for branchset 1", :directory => @directory )
		branchset1 = Treequel::Branchset.new( branch1 )
		branch2 = double( "branch for branchset 2", :directory => @directory )
		branchset2 = Treequel::Branchset.new( branch2 )

		expect( Treequel::Branchset ).to receive( :new ).with( :non_branchset1 ).
			and_return( branchset1 )
		expect( Treequel::Branchset ).to receive( :new ).with( :non_branchset2 ).
			and_return( branchset2 )

		collection = Treequel::BranchCollection.new( :non_branchset1, :non_branchset2 )

		expect( collection.branchsets ).to include( branchset1, branchset2 )
	end

	it "allows new Branchsets to be appended to it" do
		branchset1 = double( "branchset 1" )
		branchset2 = double( "branchset 2" )

		collection = Treequel::BranchCollection.new
		collection << branchset1 << branchset2

		expect( collection ).to include( branchset1, branchset2 )
	end

	it "allows new Branches to be appended to it" do
		branch1 = double( "branch 1", :branchset => :branchset1 )
		branch2 = double( "branch 2", :branchset => :branchset2 )

		collection = Treequel::BranchCollection.new
		collection << branch1 << branch2

		expect( collection ).to include( :branchset1, :branchset2 )
	end


	describe "instance with two Branchsets" do

		before( :each ) do
			# @branchset1 = double( "branchset 1", :dn => 'cn=example1,dc=acme,dc=com', :each => 1 )
			# @branchset2 = double( "branchset 2", :dn => 'cn=example2,dc=acme,dc=com', :each => 1 )
			@branch1 = double( "branch1", :directory => @directory, :dn => '' )
			@branchset1 = Treequel::Branchset.new( @branch1 )

			@branch2 = double( "branch2", :directory => @directory )
			@branchset2 = Treequel::Branchset.new( @branch2 )

			@collection = Treequel::BranchCollection.new( @branchset1, @branchset2 )
		end

		it "knows that it is empty if all of its branchsets are empty" do
			expect( @branchset1 ).to receive( :empty? ).and_return( true )
			expect( @branchset2 ).to receive( :empty? ).and_return( true )

			expect( @collection ).to be_empty()
		end

		it "knows that it is not empty if one of its branchsets has matching entries" do
			expect( @branchset1 ).to receive( :empty? ).and_return( true )
			expect( @branchset2 ).to receive( :empty? ).and_return( false )

			expect( @collection ).to_not be_empty()
		end

		it "fetches all of the results from each of its branchsets if asked for all results" do
			expect( @branchset1 ).to receive( :each ).and_yield( :bs1_stuff )
			expect( @branchset2 ).to receive( :each ).and_yield( :bs2_stuff )

			expect( @collection.all ).to eq( [ :bs1_stuff, :bs2_stuff ] )
		end

		it "fetches the first Branch returned by any of its branchsets when asked" do
			expect( @branchset1 ).to receive( :first ).and_return( nil )
			expect( @branchset2 ).to receive( :first ).and_return( :a_branch )

			expect( @collection.first ).to eq( :a_branch )
		end

		it "returns a clone of itself with an additional Branchset if a Branchset is added to it" do
			branch3 = double( "branch 3", :directory => @directory )
			branchset3 = Treequel::Branchset.new( branch3 )

			new_collection = @collection + branchset3

			expect( new_collection ).to be_an_instance_of( Treequel::BranchCollection )
			expect( new_collection ).to include( @branchset1, @branchset2, branchset3 )
		end

		it "returns all of the results from each of its branchsets plus the added branch if a " +
		   "Branch is added to it" do
			expect( @branchset1 ).to receive( :each ).and_yield( :bs1_stuff )
			expect( @branchset2 ).to receive( :each ).and_yield( :bs2_stuff )
			added_branch = double( "added branch", :directory => @directory )
			expect( added_branch ).to receive( :to_ary ).and_return( [added_branch] )

			results = @collection + added_branch

			expect( results.length ).to eq( 3 )
			expect( results ).to include( :bs1_stuff, :bs2_stuff, added_branch )
		end

		it "returns all of the results from each of its branchsets minus the subtracted branch " +
		   "if a Branch is subtracted from it" do
			results_branch1 = double( "results branch 1", :dn => TEST_PERSON_DN )
			results_branch2 = double( "results branch 2", :dn => TEST_PERSON2_DN )
			subtracted_branch = double( "subtracted branch", :dn => TEST_PERSON_DN )

			expect( @branchset1 ).to receive( :each ).and_yield( results_branch1 )
			expect( @branchset2 ).to receive( :each ).and_yield( results_branch2 )

			results = @collection - subtracted_branch

			expect( results.length ).to eq( 1 )
			expect( results ).to_not include( subtracted_branch )
			expect( results ).to_not include( results_branch1 )
		end

		it "returns a clone of itself with both collections' Branchsets if a BranchCollection is " +
		   "added to it" do
			branch3 = double( "branch for branchset 3", :directory => @directory )
			branchset3 = Treequel::Branchset.new( branch3 )
			branch4 = double( "branch for branchset 4", :directory => @directory )
			branchset4 = Treequel::Branchset.new( branch4 )

			other_collection = Treequel::BranchCollection.new( branchset3, branchset4 )

			new_collection = @collection + other_collection

			expect( new_collection ).to be_an_instance_of( Treequel::BranchCollection )
			expect( new_collection ).to include( @branchset1, @branchset2, branchset3, branchset4 )
		end

		it "returns a new BranchCollection with the union of Branchsets if it is ORed with " +
		   "another BranchCollection" do
			branch3 = double( "branch for branchset 3", :directory => @directory )
			branchset3 = Treequel::Branchset.new( branch3 )
			branch4 = double( "branch for branchset 4", :directory => @directory )
			branchset4 = Treequel::Branchset.new( branch4 )

			other_collection = Treequel::BranchCollection.new( branchset3, branchset4 )

			new_collection = @collection | other_collection

			expect( new_collection ).to be_an_instance_of( Treequel::BranchCollection )
			expect( new_collection ).to include( @branchset1, @branchset2, branchset3, branchset4 )
		end

		it "returns a new BranchCollection with the intersection of Branchsets if it is ANDed with " +
		   "another BranchCollection" do
			branch3 = double( "branch for branchset 3", :directory => @directory )
			branchset3 = Treequel::Branchset.new( branch3 )
			branch4 = double( "branch for branchset 4", :directory => @directory )
			branchset4 = Treequel::Branchset.new( branch4 )

			other_collection = Treequel::BranchCollection.new( @branchset2, branchset3, branchset4 )
			@collection << branchset4

			new_collection = @collection & other_collection

			expect( new_collection ).to be_an_instance_of( Treequel::BranchCollection )
			expect( new_collection ).to include( @branchset2, branchset4 )
		end

		it "can create a clone of itself with filtered branchsets" do
			branch3 = double( "branch for branchset 3", :directory => @directory )
			filtered_branchset1 = Treequel::Branchset.new( branch3 )
			branch4 = double( "branch for branchset 4", :directory => @directory )
			filtered_branchset2 = Treequel::Branchset.new( branch4 )

			expect( @branchset1 ).to receive( :filter ).with( :cn => 'chunkalicious' ).
				and_return( filtered_branchset1 )
			expect( @branchset2 ).to receive( :filter ).with( :cn => 'chunkalicious' ).
				and_return( filtered_branchset2 )

			filtered_collection = @collection.filter( :cn => 'chunkalicious' )
			expect( filtered_collection ).to_not be_equal( @collection )
			expect( filtered_collection ).to include( filtered_branchset1, filtered_branchset2 )
		end

		it "raises a reasonable exception if one of its delegates returns a non-branchset" do
			filter = Treequel::Filter.new

			expect {
				@collection.filter
			}.to raise_exception( ArgumentError, /0 for 1/ )
		end

		# it "can create a clone of itself with ordered branchsets" do
		# 	ordered_branchset1 = double( "branchset 3", :dn => 'cn=example3,dc=acme,dc=com', :each => 1 )
		# 	ordered_branchset2 = double( "branchset 4", :dn => 'cn=example4,dc=acme,dc=com', :each => 1 )
		# 	expect( @branchset1 ).to receive( :order ).with( :cn ).
		# 		and_return( ordered_branchset1 )
		#  	expect( @branchset2 ).to receive( :order ).with( :cn ).
		# 		and_return( ordered_branchset2 )
		# 
		# 	ordered_collection = @collection.order( :cn )
		#  	expect( ordered_collection ).to_not be_equal( @collection )
		#  	expect( ordered_collection ).to include( ordered_branchset1, ordered_branchset2 )
		# end
		# 
		it "can return the base DNs of all of its branchsets" do
			expect( @branchset1 ).to receive( :base_dn ).and_return( :branchset1_basedn )
			expect( @branchset2 ).to receive( :base_dn ).and_return( :branchset2_basedn )
			expect( @collection.base_dns ).to eq( [ :branchset1_basedn, :branchset2_basedn ] )
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

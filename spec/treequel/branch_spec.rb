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

	require 'treequel/branch'
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

describe Treequel::Branch do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@directory = mock( "treequel directory", :get_entry => :an_entry_hash )
	end


	it "can be constructed from a DN" do
		@directory.should_receive( :rdn_to ).with( TEST_PEOPLE_DN ).
			and_return( TEST_PEOPLE_RDN     )
		@directory.should_receive( TEST_PEOPLE_DN_ATTR ).with( TEST_PEOPLE_DN_VALUE ).and_return do 
			args = [@directory, TEST_PEOPLE_DN_ATTR, TEST_PEOPLE_DN_VALUE, TEST_BASE_DN]
			Treequel::Branch.new( *args ) 
		end

		branch = Treequel::Branch.new_from_dn( TEST_PEOPLE_DN, @directory )
		branch.dn.should == TEST_PEOPLE_DN
	end

	it "can be constructed from an entry returned from LDAP::Conn.search2"  do
		entry = {
			'dn'                => [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		branch.attribute.should == TEST_PERSON_DN_ATTR
		branch.value.should == TEST_PERSON_DN_VALUE
		branch.entry.should == entry
	end


	describe "instances" do

		before( :each ) do
			@branch = Treequel::Branch.new(
				@directory, 
				TEST_HOSTS_DN_ATTR, 
				TEST_HOSTS_DN_VALUE,
				TEST_BASE_DN
			  )
		end


		it "knows what the attribute and value pair part of its DN are" do
			@branch.rdn.should == TEST_HOSTS_RDN
		end

		it "knows what its DN is" do
			@branch.dn.should == TEST_HOSTS_DN
		end

		it "fetch their LDAP::Entry from the directory if they don't already have one" do
			@directory.should_receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( :the_entry )

			@branch.entry.should == :the_entry
			@branch.entry.should == :the_entry
		end

		it "returns a human-readable representation of itself for #inspect" do
			entry = mock( "entry object" )
			@directory.should_receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( entry )
			entry.should_receive( :inspect ).
				and_return( 'inspected_entry' )

			rval = @branch.inspect

			rval.should =~ /#{TEST_HOSTS_DN_ATTR}/i
			rval.should =~ /#{TEST_HOSTS_DN_VALUE}/
			rval.should =~ /#{TEST_BASE_DN}/
			rval.should =~ /\binspected_entry\b/
		end


		it "implement a proxy method that allow for creation of sub-branches" do
			rval = @branch.cn( 'rondori' )
			rval.dn.should == "cn=rondori,#{TEST_HOSTS_DN}"

			rval2 = rval.ou( 'Config' )
			rval2.dn.should == "ou=Config,cn=rondori,#{TEST_HOSTS_DN}"
		end

		it "don't try to create sub-branches for method calls with more than one parameter" do
			lambda {
				@branch.dc( 'sbc', 'glar' )
			}.should raise_error( ArgumentError, /wrong number of arguments/ )
		end


		it "can return all of its immediate children as Branches"
		it "can return its parent as a Branch"


		it "can construct a Treequel::Branchset that uses it as its base" do
			branchset = stub( "branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )

			@branch.branchset.should == branchset
		end

		it "can create a filtered Treequel::Branchset for itself" do
			branchset = mock( "filtered branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :filter ).with( {:cn => 'acme'} ).
				and_return( :a_filtered_branchset )

			@branch.filter( :cn => 'acme' ).should == :a_filtered_branchset
		end

		it "doesn't restrict the number of arguments passed to #filter (bugfix)" do
			branchset = mock( "filtered branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :filter ).with( :uid, [:glumpy, :grumpy, :glee] ).
				and_return( :a_filtered_branchset )

			@branch.filter( :uid, [:glumpy, :grumpy, :glee] ).should == :a_filtered_branchset
		end

		it "creates a scoped Treequel::Branchset for itself" do
			branchset = mock( "scoped branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :scope ).with( :onelevel ).
				and_return( :a_scoped_branchset )

			@branch.scope( :onelevel ).should == :a_scoped_branchset
		end

		it "creates a selective Treequel::Branchset for itself" do
			branchset = mock( "selective branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :select ).with( :uid, :l, :familyName, :givenName ).
				and_return( :a_selective_branchset )

			@branch.select( :uid, :l, :familyName, :givenName ).should == :a_selective_branchset
		end


		### Attribute reader
		describe "index fetch operator" do

			before( :each ) do
				@schema = mock( "treequel schema" )
				@entry = mock( "entry object" )
				@directory.stub!( :schema ).and_return( @schema )
				@directory.stub!( :get_entry ).and_return( @entry )
			end


			it "fetches a multi-value attribute as an Array" do
				@attribute_type = mock( "schema attribute type object" )
				@schema.should_receive( :attribute_types ).and_return({ :glumpy => @attribute_type })
				@attribute_type.should_receive( :single? ).and_return( false )
				@entry.should_receive( :[] ).with( 'glumpy' ).at_least( :once ).
					and_return([ 'glumpa1', 'glumpa2' ])

				@branch[ :glumpy ].should == [ 'glumpa1', 'glumpa2' ]
			end

			it "fetches a single-value attribute as a scalar" do
				@attribute_type = mock( "schema attribute type object" )
				@schema.should_receive( :attribute_types ).and_return({ :glumpy => @attribute_type })
				@attribute_type.should_receive( :single? ).and_return( true )
				@entry.should_receive( :[] ).with( 'glumpy' ).at_least( :once ).
					and_return([ 'glumpa1' ])

				@branch[ :glumpy ].should == 'glumpa1'
			end

			it "returns nil if there is no such attribute in the schema" do
				@schema.should_receive( :attribute_types ).and_return({})
				@branch[ :glumpy ].should == nil
			end

			it "returns nil if record doesn't have the attribute set" do
				@schema.should_receive( :attribute_types ).and_return({ :glumpy => @attribute_type })
				@branch[ :glumpy ].should == nil
			end

		end
	end

end


# vim: set nosta noet ts=4 sw=4:

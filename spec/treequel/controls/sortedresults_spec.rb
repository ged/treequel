# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'treequel'
require 'treequel/branchset'
require 'treequel/behavior/control'
require 'treequel/controls/sortedresults'


describe Treequel::SortedResultsControl do

	before( :each ) do
		@conn = double( "ldap connection object" )
		allow( @conn ).to receive( :bound? ).and_return( false )
		@directory = get_fixtured_directory( @conn )
		@directory.register_controls( Treequel::SortedResultsControl )

		@branch = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )
		@branchset = @branch.branchset
	end


	it_should_behave_like "A Treequel::Control"


	it "adds a sort_order_criteria attribute to extended branchsets" do
		expect( @branchset ).to respond_to( :sort_order_criteria )
	end


	it "can add the listed attributes as ascending sort order criteria via an #order mutator " +
	   "with Symbol attribute names" do
		criteria = @branchset.order( :attr1, :attr2 ).sort_order_criteria
		expect( criteria.length ).to eq( 2 )

		expect( criteria[0].type ).to eq( 'attr1' )
		expect( criteria[0].ordering_rule ).to eq( nil )
		expect( criteria[0].reverse_order ).to be_falsey()

		expect( criteria[1].type ).to eq( 'attr2' )
		expect( criteria[1].ordering_rule ).to eq( nil )
		expect( criteria[1].reverse_order ).to be_falsey()
	end

	it "can add the listed attributes as descending sort order criteria via an #order mutator " +
	   "with Sequel::SQL::Expressions" do
		pending "requires the 'sequel' library" unless Sequel.const_defined?( :Model )
		criteria = @branchset.order( :attr1.desc ).sort_order_criteria

		expect( criteria.length ).to eq( 1 )
		expect( criteria[0].type ).to eq( 'attr1' )
		expect( criteria[0].ordering_rule ).to eq( nil )
		expect( criteria[0].reverse_order ).to be_truthy()
	end

	it "can remove existing sort order criteria via the #order mutator with no arguments" do
		ordered_branchset = @branchset.order( :attr1 )
		expect( ordered_branchset.order().sort_order_criteria ).to be_empty()
	end

	it "can remove any existing sort order criteria via an #unordered mutator" do
		ordered_branchset = @branchset.order( :attr1 )
		expect( ordered_branchset.unordered.sort_order_criteria ).to be_empty()
	end

	it "can remove any existing sort order criteria from the receiver via the #unordered! " +
	   "imperative method" do
		ordered_branchset = @branchset.order( :attr1 )
		ordered_branchset.unordered!
		expect( ordered_branchset.sort_order_criteria ).to be_empty()
	end

	it "injects the correct server-control structure into the search when iterating" do
		oid = Treequel::SortedResultsControl::OID
		expected_asn1_string = "0\x060\x04\x04\x02cn"
		expected_control = LDAP::Control.new( oid, expected_asn1_string, true )

		resultbranch = double( "Sorted result branch" )
		resultcontrol = double( "Sorted result control" )

		expect( @branch ).to receive( :search ).with( :subtree,
			instance_of(Treequel::Filter),
			{
				:limit           => 0,
				:selectattrs     => [],
				:timeout         => 0,
				:server_controls => [ expected_control ],
				:client_controls => []
			}
		  ).and_yield( resultbranch )

		expect( resultbranch ).to receive( :controls ).and_return([ resultcontrol ])
		expect( resultcontrol ).to receive( :oid ).
			and_return( Treequel::SortedResultsControl::RESPONSE_OID )
		expect( resultcontrol ).to receive( :decode ).
			and_return([ 0, :ignored ]) # 0 == Success

		@branchset.order( :cn ).each do |*args|
			expect( args ).to eq( [ resultbranch ] )
		end
	end

	it "raises an exception if the server returned an error in the response control" do
		resultbranch = double( "Sorted result branch" )
		resultcontrol = double( "Sorted result control" )

		expect( @branch ).to receive( :search ).and_yield( resultbranch )

		expect( resultbranch ).to receive( :controls ).and_return([ resultcontrol ])
		expect( resultcontrol ).to receive( :oid ).
			and_return( Treequel::SortedResultsControl::RESPONSE_OID )
		expect( resultcontrol ).to receive( :decode ).
			and_return([ 16, :ignored ]) # 16 == 'No such attribute'

		expect {
			@branchset.order( :cn ).each {}
		}.to raise_exception( Treequel::ControlError, /no such attribute/i )
	end

	it "doesn't add a sort control if no sort order criteria have been set" do
		resultbranch = double( "Result branch" )

		expect( @branch ).to receive( :search ).with( :subtree,
			instance_of(Treequel::Filter),
			{
				:limit           => 0,
				:selectattrs     => [],
				:timeout         => 0,
				:server_controls => [],
				:client_controls => []
			}
		  ).and_yield( resultbranch )

		expect( resultbranch ).to receive( :controls ).and_return( [] )

		@branchset.unordered.each do |*args|
			expect( args ).to eq( [ resultbranch ] )
		end
	end

end

# vim: set nosta noet ts=4 sw=4:

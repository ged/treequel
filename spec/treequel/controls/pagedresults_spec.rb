# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'treequel'
require 'treequel/behavior/control'
require 'treequel/controls/pagedresults'


describe Treequel::PagedResultsControl do

	let( :conn ) { instance_double(LDAP::Conn, :bound? => false) }
	let( :directory ) do
		dir = get_fixtured_directory( conn )
		dir.register_controls( Treequel::PagedResultsControl )
		dir
	end

	let( :branch ) { Treequel::Branch.new( directory, TEST_PEOPLE_DN ) }
	let( :branchset ) { branch.branchset }


	it_should_behave_like "A Treequel::Control"


	it "adds a paged_results_setsize attribute to extended branchsets" do
		expect( branchset ).to respond_to( :paged_results_setsize )
	end

	it "adds a paged_results_cookie attribute to extended branchsets" do
		expect( branchset ).to respond_to( :paged_results_cookie )
	end

	it "can add paging of a specific size to a Branchset via the #with_paged_results mutator" do
		expect( branchset.with_paged_results( 17 ).paged_results_setsize ).to eq( 17 )
	end

	it "can create an unpaged Branchset from a paged one by passing nil to #with_paged_results" do
		paged_branchset = branchset.with_paged_results( 25 )
		expect( paged_branchset.with_paged_results( nil ).paged_results_setsize ).to eq( nil )
	end

	it "can create an unpaged Branchset from a paged one by passing 0 to #with_paged_results" do
		paged_branchset = branchset.with_paged_results( 25 )
		expect( paged_branchset.with_paged_results( 0 ).paged_results_setsize ).to eq( nil )
	end

	it "can create an unpaged Branchset from a paged one via the #without_paging mutator" do
		paged_branchset = branchset.with_paged_results( 25 )
		expect( paged_branchset.without_paging.paged_results_setsize ).to eq( nil )
	end

	it "can remove any existing paging from a Branchset via the #without_paging! imperative method" do
		paged_branchset = branchset.with_paged_results( 25 )
		paged_branchset.without_paging!
		expect( paged_branchset.paged_results_setsize ).to eq( nil )
	end

	it "knows that there are (potentially) more paged results if the cookie isn't set" do
		paged_branchset = branchset.with_paged_results( 25 )
		expect( paged_branchset ).to_not be_done_paging()
	end

	it "knows that there are more paged results if the cookie is set" do
		paged_branchset = branchset.with_paged_results( 25 )
		paged_branchset.paged_results_cookie = "\230\t\000\000\000\000\000\000"
		expect( paged_branchset ).to_not be_done_paging()
	end

	it "knows that there are no more paged results if the cookie is blank" do
		paged_branchset = branchset.with_paged_results( 25 )
		paged_branchset.paged_results_cookie = ''
		expect( paged_branchset ).to be_done_paging()
	end

	it "injects the correct server-control structure into the search when iterating" do
		oid = Treequel::PagedResultsControl::OID
		expected_asn1_string = "0\005\002\001\031\004\000"
		expected_control = LDAP::Control.new( oid, expected_asn1_string, true )

		resultbranch  = double( "Paged result branch" )
		resultcontrol = double( "Paged result control" )

		expect( branch ).to receive( :search ).with( :subtree,
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
			and_return( Treequel::PagedResultsControl::OID )
		expect( resultcontrol ).to receive( :decode ).and_return([ 25, "cookievalue" ])

		branchset.with_paged_results( 25 ).each do |*args|
			expect( args ).to eq( [ resultbranch ] )
		end
	end

	it "doesn't add a paging control if no set size has been set" do
		resultbranch = double( "Result branch" )

		expect( branch ).to receive( :search ).with( :subtree,
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

		branchset.without_paging.each do |*args|
			expect( args ).to eq( [ resultbranch ] )
		end
	end


end

# vim: set nosta noet ts=4 sw=4:

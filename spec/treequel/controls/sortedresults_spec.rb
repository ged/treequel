#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/control_behavior'

require 'treequel'
require 'treequel/branchset'
require 'treequel/controls/sortedresults'


#####################################################################
###	C O N T E X T S
#####################################################################
describe Treequel::SortedResultsControl do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@branch = mock( "Branch", :dn => 'cn=example,dc=acme,dc=com' )
		@directory = mock( "Directory" )

		@branch.stub( :directory ).and_return( @directory )
		@directory.stub( :registered_controls ).and_return([ Treequel::SortedResultsControl ])
		@branchset = Treequel::Branchset.new( @branch )

	end

	after( :all ) do
		reset_logging()
	end


	it_should_behave_like "A Treequel::Control"


	it "adds a sort_order_criteria attribute to extended branchsets" do
		@branchset.should respond_to( :sort_order_criteria )
	end


	it "can add the listed attributes as ascending sort order criteria via an #order mutator " +
	   "with Symbol attribute names" do
		criteria = @branchset.order( :attr1, :attr2 ).sort_order_criteria
		criteria.should have( 2 ).members

		criteria[0].type.should == 'attr1'
		criteria[0].ordering_rule.should == nil
		criteria[0].reverse_order.should be_false()

		criteria[1].type.should == 'attr2'
		criteria[1].ordering_rule.should == nil
		criteria[1].reverse_order.should be_false()
	end

	it "can add the listed attributes as descending sort order criteria via an #order mutator " +
	   "with Sequel::SQL::Expressions" do
		pending "requires the 'sequel' library" unless Sequel.const_defined?( :Model )
		criteria = @branchset.order( :attr1.desc ).sort_order_criteria

		criteria.should have( 1 ).member
		criteria[0].type.should == 'attr1'
		criteria[0].ordering_rule.should == nil
		criteria[0].reverse_order.should be_true()
	end

	it "can remove existing sort order criteria via the #order mutator with no arguments" do
		ordered_branchset = @branchset.order( :attr1 )
		ordered_branchset.order().sort_order_criteria.should be_empty()
	end

	it "can remove any existing sort order criteria via an #unordered mutator" do
		ordered_branchset = @branchset.order( :attr1 )
		ordered_branchset.unordered.sort_order_criteria.should be_empty()
	end

	it "can remove any existing sort order criteria from the receiver via the #unordered! " +
	   "imperative method" do
		ordered_branchset = @branchset.order( :attr1 )
		ordered_branchset.unordered!
		ordered_branchset.sort_order_criteria.should be_empty()
	end

	it "injects the correct server-control structure into the search when iterating" do
		oid = Treequel::SortedResultsControl::OID
		expected_asn1_string = "0\x060\x04\x04\x02cn"
		expected_control = LDAP::Control.new( oid, expected_asn1_string, true )

		resultbranch = mock( "Sorted result branch" )
		resultcontrol = mock( "Sorted result control" )

		@branch.should_receive( :search ).with( :subtree,
			instance_of(Treequel::Filter),
			{
				:limit           => 0,
				:selectattrs     => [],
				:timeout         => 0,
				:server_controls => [ expected_control ],
				:client_controls => []
			}
		  ).and_yield( resultbranch )

		resultbranch.should_receive( :controls ).and_return([ resultcontrol ])
		resultcontrol.should_receive( :oid ).
			and_return( Treequel::SortedResultsControl::RESPONSE_OID )
		resultcontrol.should_receive( :decode ).
			and_return([ 0, :ignored ]) # 0 == Success

		@branchset.order( :cn ).each do |*args|
			args.should == [ resultbranch ]
		end
	end

	it "raises an exception if the server returned an error in the response control" do
		resultbranch = mock( "Sorted result branch" )
		resultcontrol = mock( "Sorted result control" )

		@branch.should_receive( :search ).and_yield( resultbranch )

		resultbranch.should_receive( :controls ).and_return([ resultcontrol ])
		resultcontrol.should_receive( :oid ).
			and_return( Treequel::SortedResultsControl::RESPONSE_OID )
		resultcontrol.should_receive( :decode ).
			and_return([ 16, :ignored ]) # 16 == 'No such attribute'

		expect {
			@branchset.order( :cn ).each {}
		}.to raise_exception( Treequel::ControlError, /no such attribute/i )
	end

	it "doesn't add a sort control if no sort order criteria have been set" do
		resultbranch = mock( "Result branch" )

		@branch.should_receive( :search ).with( :subtree,
			instance_of(Treequel::Filter),
			{
				:limit           => 0,
				:selectattrs     => [],
				:timeout         => 0,
				:server_controls => [],
				:client_controls => []
			}
		  ).and_yield( resultbranch )

		resultbranch.should_receive( :controls ).and_return( [] )

		@branchset.unordered.each do |*args|
			args.should == [ resultbranch ]
		end
	end

end

# vim: set nosta noet ts=4 sw=4:

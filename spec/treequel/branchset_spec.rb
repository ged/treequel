# -*- ruby -*-
#encoding: utf-8

require_relative '../spec_helpers'

require 'treequel/branchset'
require 'treequel/branchcollection'
require 'treequel/control'


describe Treequel::Branchset do

	DEFAULT_PARAMS = {
		:limit           => 0,
		:selectattrs     => [],
		:timeout         => 0,
		:client_controls => [],
		:server_controls => [],
	}


	before( :each ) do
		@conn = double( "LDAP connection", :set_option => true, :bound? => false )
		@directory = get_fixtured_directory( @conn )
		@branch = @directory.base
		@params = DEFAULT_PARAMS.dup
	end


	context "an instance" do
		before( :each ) do
			@branchset = Treequel::Branchset.new( @branch )
		end

		it "is Enumerable" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_BASE_DN, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=*)",
				      [], false, [], [], 0, 0, 0, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup ])

			@branchset.all? {|b| b.dn }
		end

		#
		# #empty?
		#
		it "is empty if it doesn't match at least one entry" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_BASE_DN, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=*)",
				      [], false, [], [], 0, 0, 1, "", nil ).
				and_return([ ])
			expect( @branchset ).to be_empty()
		end

		it "isn't empty if it matches at least one entry" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_BASE_DN, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=*)",
				      [], false, [], [], 0, 0, 1, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup ])
			expect( @branchset ).to_not be_empty()
		end

		#
		# #map
		#
		it "can be mapped into an Array of attribute values" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_BASE_DN, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=*)",
				      [], false, [], [], 0, 0, 0, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup, TEST_PEOPLE_ENTRY.dup ])

			expect( @branchset.map( :ou ) ).to eq( [ ['Hosts'], ['People'] ] )
		end


		#
		# #to_hash
		#
		it "can be mapped into a Hash of entries keyed by one of its attributes" do
			expect( @conn ).to receive( :search_ext2 ).
				with( "dc=acme,dc=com", 2, "(objectClass=*)", [], false, [], [], 0, 0, 0, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup, TEST_PEOPLE_ENTRY.dup ])

			hosthash = TEST_HOSTS_ENTRY.dup
			hosthash.delete( 'dn' )
			peoplehash = TEST_PEOPLE_ENTRY.dup
			peoplehash.delete( 'dn' )

			expect( @branchset.to_hash( :ou ) ).to eq({
				'Hosts'  => hosthash,
				'People' => peoplehash,
			})
		end


		it "can be mapped into a Hash of tuples using two attributes" do
			expect( @conn ).to receive( :search_ext2 ).
				with( "dc=acme,dc=com", 2, "(objectClass=*)", [], false, [], [], 0, 0, 0, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup, TEST_PEOPLE_ENTRY.dup ])

			expect( @branchset.to_hash( :ou, :description ) ).to eq({
				'Hosts'  => TEST_HOSTS_ENTRY['description'].first,
				'People' => TEST_PEOPLE_ENTRY['description'].first,
			})
		end

		#
		# #+
		#
		it "can be combined with another instance into a BranchCollection by adding them together" do
			other_branch = @directory.ou( :people )
			other_branchset = Treequel::Branchset.new( other_branch )

			result = @branchset + other_branchset
			expect( result ).to be_a( Treequel::BranchCollection )
			expect( result.branchsets.length ).to eq( 2 )
			expect( result.branchsets ).to include( @branchset, other_branchset )
		end

		it "returns the results of the search with the additional Branch if one is added to it" do
			expect( @conn ).to receive( :search_ext2 ).
				with( "dc=acme,dc=com", 2, "(objectClass=*)", [], false, [], [], 0, 0, 0, "", nil ).
				and_return([ TEST_HOSTS_ENTRY.dup, TEST_PEOPLE_ENTRY.dup ])

			other_branch = @directory.ou( :netgroups )

			result = @branchset + other_branch
			expect( result.length ).to eq( 3 )
			expect( result ).to include( other_branch )
		end

		#
		# #-
		#
		it "returns the results of the search without the specified object if an object is " +
		     "subtracted from it" do
				otherbranch = @directory.ou( :people )

				expect( @conn ).to receive( :search_ext2 ).
					with( "dc=acme,dc=com", 2, "(objectClass=*)", [], false, [], [], 0, 0, 0, "", nil ).
					and_return([ TEST_HOSTS_ENTRY.dup, TEST_PEOPLE_ENTRY.dup ])

				result = @branchset - otherbranch
				expect( result.length ).to eq( 1 )
				expect( result ).to_not include( otherbranch )
		end

	end

	context "instance with no filter, options, or scope set" do

		before( :each ) do
			@branchset = Treequel::Branchset.new( @branch )
		end

		it "can clone itself with merged options" do
			newset = @branchset.clone( :scope => :one )
			expect( newset ).to be_a( Treequel::Branchset )
			expect( newset ).to_not equal( @branchset )
			expect( newset.options ).to_not equal( @branchset.options )
			expect( newset.scope ).to eq( :one )
		end


		#
		# #filter
		#

		it "generates a valid filter string" do
			expect( @branchset.filter_string ).to eq( '(objectClass=*)' )
		end


		it "performs a search using the default filter and scope when all records are requested" do
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, @params ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [ :matching_branches ] )
		end

		it "performs a search using the default filter, scope, and a limit of 1 when the first " +
		   "record is requested" do
			params = @params.merge( :limit => 1 )
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, params ).
				and_return( [:first_matching_branch, :other_branches] )

			expect( @branchset.first ).to eq( :first_matching_branch )
		end

		it "performs a search using the default filter, scope, and a limit of 5 when the first " +
		   "five records are requested" do
			params = @params.merge( :limit => 5 )
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter, params ).
				and_return( [:branch1, :branch2, :branch3, :branch4, :branch5] )

			expect( @branchset.first( 5 ) ).to eq( [:branch1, :branch2, :branch3, :branch4, :branch5] )
		end

		it "creates a new branchset cloned from itself with the specified filter" do
			newset = @branchset.filter( :clothing, 'pants' )
			expect( newset.filter_string ).to eq( '(clothing=pants)' )
		end

		#
		# #or
		#

		it "creates a new branchset cloned from itself with an OR clause added to to an " +
		   "existing filter" do
			pantset = @branchset.filter( :clothing => 'pants' )
			bothset = pantset.or( :clothing => 'shirt' )

			expect( bothset.filter_string ).to eq( '(|(clothing=pants)(clothing=shirt))' )
		end

		it "raises an exception if #or is invoked without an existing filter" do
			expect {
				@branchset.or( :clothing => 'shirt' )
			}.to raise_exception( Treequel::ExpressionError, /no existing filter/i )
		end


		#
		# not
		#
		it "can create a new branchset cloned from itself with a NOT clause added to an " +
		   "existing filter" do
			pantset = @branchset.filter( :clothing => 'pants' )
			notsmallset = pantset.not( :size => 'small' )

			expect( notsmallset.filter_string ).to eq( '(&(clothing=pants)(!(size=small)))' )
		end


		#
		# #scope
		#

		it "provides a reader for its scope" do
			expect( @branchset.scope ).to eq( :subtree )
		end

		it "can return the DN of its base" do
			expect( @branch ).to receive( :dn ).and_return( :foo )
			expect( @branchset.base_dn ).to eq( :foo )
		end

		it "can create a new branchset cloned from itself with a different scope" do
			newset = @branchset.scope( :onelevel )
			expect( newset ).to be_a( Treequel::Branchset )
			expect( newset ).to_not equal( @branchset )
			expect( newset.options ).to_not equal( @branchset.options )
			expect( newset.scope ).to eq( :onelevel )
		end

		it "can create a new branchset cloned from itself with a different string scope" do
			newset = @branchset.scope( 'sub' )
			expect( newset.scope ).to eq( :sub )
		end

		it "uses its scope setting as the scope to use when searching" do
			@branchset.options[:scope] = :onelevel
			expect( @branch ).to receive( :search ).
				with( :onelevel, @branchset.filter, @params ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [:matching_branches] )
		end

		#
		# #select
		#
		it "can create a new branchset cloned from itself with an attribute selection" do
			newset = @branchset.select( :l, :lastName, :disabled )
			expect( newset.select ).to eq( [ 'l', 'lastName', 'disabled' ] )
		end

		it "can create a new branchset cloned from itself with all attributes selected" do
			newset = @branchset.select_all
			expect( newset.select ).to eq( [] )
		end

		it "can create a new branchset cloned from itself with additional attributes selected" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			newset = @branchset.select_more( :firstName, :uid, :lastName )
			expect( newset.select ).to eq( [ 'l', 'cn', 'uid', 'firstName', 'lastName' ] )
		end

		it "adding attributes via #select_more should work even if there was no current " +
		   "attribute selection" do
			newset = @branchset.select_more( :firstName, :uid, :lastName, :objectClass )
			expect( newset.select ).to include( 'uid', 'firstName', 'lastName', 'objectClass' )
		end

		it "uses its selection as the list of attributes to fetch when searching" do
			@branchset.options[:select] = [ :l, :cn, :uid ]
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter,
				      @params.merge(:selectattrs => ['l', 'cn', 'uid']) ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [:matching_branches] )
		end

		#
		# #timeout
		#

		it "can create a new branchset cloned from itself with a timeout" do
			newset = @branchset.timeout( 30 )
			expect( newset.timeout ).to eq( 30.0 )
		end

		it "can create a new branchset cloned from itself without a timeout" do
			@branchset.options[:timeout] = 5.375
			newset = @branchset.without_timeout
			expect( newset.timeout ).to eq( 0 )
		end

		it "uses its timeout as the timeout values when searching" do
			@branchset.options[:timeout] = 5.375
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter,
				      @params.merge(:timeout => 5.375) ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [:matching_branches] )
		end


		#
		# #limit
		#
		it "can create a new branchset cloned from itself with a limit attribute" do
			newset = @branchset.limit( 5 )
			expect( newset.limit ).to eq( 5 )
		end

		it "can create a new branchset cloned from itself without a limit" do
			newset = @branchset.without_limit
			expect( newset.limit ).to eq( 0 )
		end

		it "uses its limit as the limit when searching" do
			@branchset.options[:limit] = 8
			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, @branchset.filter,
				      @params.merge(:limit => 8) ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [:matching_branches] )
		end

		#
		# #as
		#
		it "can create a new branchset cloned from itself that will return instances of a " +
		   "different branch class" do
			subclass = Class.new( Treequel::Branch )
			expect( @branch ).to receive( :directory ).and_return( :the_directory )
			expect( @branch ).to receive( :dn ).at_least( :once ).and_return( TEST_HOSTS_DN )
			newset = @branchset.as( subclass )
			expect( newset.branch ).to be_an_instance_of( subclass )
		end


		#
		# from
		#
		it "can create a new branchset cloned from itself with a different base DN (String)" do
			newset = @branchset.from( TEST_SUBHOSTS_DN )
			expect( newset.base_dn ).to eq( TEST_SUBHOSTS_DN )
		end

		it "can create a new branchset cloned from itself with a different base DN " +
		   "(Treequel::Branch)" do
			branch = Treequel::Branch.new( @directory, TEST_SUBHOSTS_DN )
			newset = @branchset.from( branch )
			expect( newset.base_dn ).to eq( TEST_SUBHOSTS_DN )
		end


		#
		# with_operational_attributes
		#
		it "can create a new branchset cloned from itself with operational attributes selected" do
			newset = @branchset.with_operational_attributes
			expect( newset.options[:select] ).to include( :+ )
		end


	end


	context "instance with no filter, and scope set to 'onelevel'" do

		before( :each ) do
			@branchset = Treequel::Branchset.new( @branch, :scope => :onelevel )
		end


		it "generates a valid filter string" do
			expect( @branchset.filter_string ).to eq( '(objectClass=*)' )
		end

		it "performs a search using the default filter and scope when all records are requested" do
			expect( @branch ).to receive( :search ).
				with( :onelevel, @branchset.filter, @params ).
				and_yield( :matching_branches )

			expect( @branchset.all ).to eq( [:matching_branches] )
		end

	end

	context "created for a directory with registered controls" do

		before( :all ) do
			@control = Module.new {
				include Treequel::Control
				OID = '3.1.4.1.5.926'

				def yep; end
				def get_client_controls; [:client_control]; end
				def get_server_controls; [:server_control]; end
			}
		end

		before( :each ) do
			allow( @directory ).to receive( :registered_controls ).and_return([ @control ])
		end

		after( :each ) do
			@directory = nil
		end

		it "extends instances of itself with any controls registered with its Branch's Directory" do
			set = Treequel::Branchset.new( @branch )
			expect( set ).to respond_to( :yep )
		end

		it "appends client controls to search arguments" do
			resultbranch = double( "Result Branch" )
			set = Treequel::Branchset.new( @branch )

			@params[:server_controls] = [:server_control]
			@params[:client_controls] = [:client_control]

			expect( @branch ).to receive( :search ).
				with( Treequel::Branchset::DEFAULT_SCOPE, set.filter, @params ).
				and_yield( resultbranch )

			expect( set.all ).to eq( [ resultbranch ] )
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

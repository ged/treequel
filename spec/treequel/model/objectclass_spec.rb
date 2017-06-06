# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'treequel/model'
require 'treequel/model/objectclass'
require 'treequel/branchset'


describe Treequel::Model::ObjectClass do

	before( :each ) do
		@conn = double( "ldap connection object" )
		@directory = get_fixtured_directory( @conn )
		Treequel::Model.directory = @directory
	end

	after( :each ) do
		Treequel::Model.directory = nil
		Treequel::Model.objectclass_registry.clear
		Treequel::Model.base_registry.clear
	end


	it "outputs a warning when it is included instead of used to extend a Module" do
		expect( Treequel::Model::ObjectClass ).to receive( :warn ).
			with( /extending.*rather than appending/i )
		mixin = Module.new do
			include Treequel::Model::ObjectClass
		end
	end


	context "extended module" do

		it "can declare a required objectClass" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			expect( mixin.model_objectclasses ).to eq( [:inetOrgPerson] )
		end

		it "can declare a required objectClass as a String" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses 'apple-computer-list'
			end

			expect( mixin.model_objectclasses ).to eq( [:'apple-computer-list'] )
		end

		it "can declare multiple required objectClasses" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson, :acmeAccount
			end

			expect( mixin.model_objectclasses ).to eq( [ :inetOrgPerson, :acmeAccount ] )
		end

		it "can declare a single base" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass,
				       Treequel::SpecConstants
				model_objectclasses :device
				model_bases TEST_PHONES_DN
			end

			expect( mixin.model_bases ).to eq( [TEST_PHONES_DN] )
		end

		it "can declare a base with spaces" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :device
				model_bases 'ou=phones, dc=acme, dc=com'
			end

			expect( mixin.model_bases ).to eq( ['ou=phones,dc=acme,dc=com'] )
		end

		it "can declare multiple bases" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass,
				       Treequel::SpecConstants
				model_objectclasses :ipHost
				model_bases TEST_HOSTS_DN,
				            TEST_SUBHOSTS_DN
			end

			expect( mixin.model_bases ).to include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
		end

		it "raises an exception when creating a search for a mixin that hasn't declared " +
		     "at least one objectClass or base"  do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
			end

			expect {
				mixin.search( @directory )
			}.to raise_exception( Treequel::ModelError, /has no search criteria defined/ )
		end

		it "defaults to using Treequel::Model as its model class" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
			end

			expect( mixin.model_class ).to eq( Treequel::Model )
		end

		it "can declare a model class other than Treequel::Model" do
			class MyModel < Treequel::Model; end
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_class MyModel
			end

			expect( mixin.model_class ).to eq( MyModel )
		end

		it "re-registers objectClasses that have already been declared when declaring a " +
		     "new model class" do
			class MyModel < Treequel::Model; end

			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
				model_class MyModel
			end

			expect( Treequel::Model.objectclass_registry[:inetOrgPerson] ).to_not include( mixin )
			expect( MyModel.objectclass_registry[:inetOrgPerson] ).to include( mixin )
		end

		it "re-registers bases that have already been declared when declaring a " +
		     "new model class" do
			class MyModel < Treequel::Model; end

			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_bases 'ou=people,dc=acme,dc=com', 'ou=notpeople,dc=acme,dc=com'
				model_class MyModel
			end

			expect( Treequel::Model.base_registry['ou=people,dc=acme,dc=com'] ).to_not include( mixin )
			expect( MyModel.base_registry['ou=people,dc=acme,dc=com'] ).to include( mixin )
		end

		it "re-registers bases that have already been declared when declaring a " +
		     "new model class" do
			class MyModel < Treequel::Model; end

			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_bases 'ou=people,dc=acme,dc=com', 'ou=notpeople,dc=acme,dc=com'
				model_class MyModel
			end

			expect( Treequel::Model.base_registry['ou=people,dc=acme,dc=com'] ).to_not include( mixin )
			expect( MyModel.base_registry['ou=people,dc=acme,dc=com'] ).to include( mixin )
		end

		it "uses the directory associated with its model_class instead of Treequel::Model's if " +
		   "its model_class is set when creating a search Branchset"  do
			conn = double( "ldap connection object" )
			directory = get_fixtured_directory( conn )

			class MyModel < Treequel::Model; end
			MyModel.directory = directory

			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
				model_class MyModel
			end

			result = mixin.search

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.branch.directory ).to eq( directory )
		end

		it "delegates Branchset methods through the Branchset returned by its #search method" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			expect( mixin.filter( :mail ) ).to be_a( Treequel::Branchset )
		end

		it "delegates Branchset Enumerable methods through the Branchset returned by its " +
		   "#search method" do
			expect( @conn ).to receive( :bound? ).and_return( true )
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_BASE_DN, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=inetOrgPerson)",
			          [], false, [], [], 0, 0, 1, "", nil ).
				and_return([ TEST_PERSON_ENTRY ])

			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			result = mixin.first

			expect( result ).to be_a( Treequel::Model )
			expect( result ).to be_a( mixin )
			expect( result.dn ).to eq( TEST_PERSON_ENTRY['dn'].first )
		end

	end

	context "model instantiation" do

		it "can instantiate a new model object with its declared objectClasses" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			result = mixin.create( TEST_PERSON_DN )
			expect( result ).to be_a( Treequel::Model )
			expect( result[:objectClass] ).to include( 'inetOrgPerson' )
			expect( result[TEST_PERSON_DN_ATTR] ).to eq( [ TEST_PERSON_DN_VALUE ] )
		end

		it "can instantiate a new model object with its declared objectClasses in a directory " +
		   "other than the one associated with its model_class" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			result = mixin.create( @directory, TEST_PERSON_DN )
			expect( result ).to be_a( Treequel::Model )
			expect( result[:objectClass] ).to include( 'inetOrgPerson' )
			expect( result[TEST_PERSON_DN_ATTR] ).to eq( [ TEST_PERSON_DN_VALUE ] )
		end

		it "doesn't add the extracted DN attribute if it's already present in the entry" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			result = mixin.create( TEST_PERSON_DN,
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] )
			expect( result ).to be_a( Treequel::Model )
			expect( result[:objectClass] ).to include( 'inetOrgPerson' )
			expect( result[TEST_PERSON_DN_ATTR].length ).to eq( 1 )
			expect( result[TEST_PERSON_DN_ATTR] ).to eq( [ TEST_PERSON_DN_VALUE ] )
		end

		it "merges objectClasses passed to the creation method" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			result = mixin.create( TEST_PERSON_DN,
				:objectClass => [:person, :inetOrgPerson] )
			expect( result ).to be_a( Treequel::Model )
			expect( result[:objectClass].length ).to eq( 2 )
			expect( result[:objectClass] ).to include( 'inetOrgPerson', 'person' )
			expect( result[TEST_PERSON_DN_ATTR].length ).to eq( 1 )
			expect( result[TEST_PERSON_DN_ATTR] ).to include( TEST_PERSON_DN_VALUE )
		end

		it "handles the creation of objects with multi-value DNs" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :ipHost, :ieee802Device, :device
			end

			result = mixin.create( TEST_HOST_MULTIVALUE_DN )
			expect( result ).to be_a( Treequel::Model )
			expect( result[:objectClass].length ).to eq( 3 )
			expect( result[:objectClass] ).to include( 'ipHost', 'ieee802Device', 'device' )
			expect( result[TEST_HOST_MULTIVALUE_DN_ATTR1] ).to include( TEST_HOST_MULTIVALUE_DN_VALUE1 )
			expect( result[TEST_HOST_MULTIVALUE_DN_ATTR2] ).to include( TEST_HOST_MULTIVALUE_DN_VALUE2 )
		end

	end

	context "module that has one required objectClass declared" do

		before( :each ) do
			@conn = double( "ldap connection object" )
			@directory = get_fixtured_directory( @conn )
			Treequel::Model.directory = @directory

			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end
		end

		after( :each ) do
			Treequel::Model.objectclass_registry.clear
		end


		it "is returned as one of the mixins for entries with only that objectClass" do
			expect( Treequel::Model.mixins_for_objectclasses(:inetOrgPerson) ).to include( @mixin )
		end

		it "is not returned in the list of mixins to apply to an entry without that objectClass" do
			expect( Treequel::Model.mixins_for_objectclasses(:device) ).to_not include( @mixin )
		end

		it "can create a Branchset that will search for applicable entries"  do
			result = @mixin.search

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_BASE_DN )
			expect( result.filter.to_s ).to eq( '(objectClass=inetOrgPerson)' )
			expect( result.branch.directory ).to eq( @directory )
		end

		it "can create a Branchset that will search for applicable entries in a Directory other " +
		   "than the one set for Treequel::Model"  do
			conn = double( "second ldap connection object" )
			directory = get_fixtured_directory( conn )

			result = @mixin.search( directory )

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_BASE_DN )
			expect( result.filter.to_s ).to eq( '(objectClass=inetOrgPerson)' )
			expect( result.branch.directory ).to eq( directory )
		end

	end

	context "module that has more than one required objectClass declared" do

		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :device, :ipHost
			end
		end

		after( :each ) do
			Treequel::Model.objectclass_registry.clear
		end


		it "is returned as one of the mixins to apply to entries with all of its required " +
		     "objectClasses" do
			expect( Treequel::Model.mixins_for_objectclasses(:device, :ipHost) ).to include( @mixin )
		end

		it "is not returned in the list of mixins to apply to an entry with only one of its " +
		     "objectClasses" do
			expect( Treequel::Model.mixins_for_objectclasses(:device) ).to_not include( @mixin )
		end

		it "can create a Branchset that will search for applicable entries"  do
			result = @mixin.search

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_BASE_DN )
			expect( result.filter.to_s ).to eq( '(&(objectClass=device)(objectClass=ipHost))' )
			expect( result.branch.directory ).to eq( @directory )
		end

		it "can create a Branchset that will search for applicable entries in a Directory other " +
		   "than the one set for Treequel::Model"  do
			conn = double( "second ldap connection object" )
			directory = get_fixtured_directory( conn )

			result = @mixin.search( directory )

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_BASE_DN )
			expect( result.filter.to_s ).to eq( '(&(objectClass=device)(objectClass=ipHost))' )
			expect( result.branch.directory ).to eq( directory )
		end

	end

	context "module that has one base declared" do
		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass,
				       Treequel::SpecConstants
				model_bases TEST_PEOPLE_DN
			end
		end

		after( :each ) do
			Treequel::Model.base_registry.clear
		end


		it "is returned as one of the mixins to apply to an entry that is a child of its base" do
			expect( Treequel::Model.mixins_for_dn(TEST_PERSON_DN) ).to include( @mixin )
		end

		it "is not returned as one of the mixins to apply to an entry that is not a child of " +
		   "its base" do
			expect( Treequel::Model.mixins_for_dn(TEST_ROOM_DN) ).to_not include( @mixin )
		end

		it "can create a Branchset that will search for applicable entries"  do
			result = @mixin.search

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_PEOPLE_DN )
			expect( result.filter.to_s ).to eq( '(objectClass=*)' )
			expect( result.branch.directory ).to eq( @directory )
		end

		it "can create a Branchset that will search for applicable entries in a Directory other " +
		   "than the one set for Treequel::Model"  do
			conn = double( "second ldap connection object" )
			directory = get_fixtured_directory( conn )

			result = @mixin.search( directory )

			expect( result ).to be_a( Treequel::Branchset )
			expect( result.base_dn ).to eq( TEST_PEOPLE_DN )
			expect( result.filter.to_s ).to eq( '(objectClass=*)' )
			expect( result.branch.directory ).to eq( directory )
		end

	end

	context "module that has more than one base declared" do
		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass,
				       Treequel::SpecConstants
				model_bases TEST_HOSTS_DN,
				            TEST_SUBHOSTS_DN
			end
		end

		after( :each ) do
			Treequel::Model.base_registry.clear
		end


		it "is returned as one of the mixins to apply to an entry that is a child of one of " +
		   "its bases" do
			expect( Treequel::Model.mixins_for_dn(TEST_SUBHOST_DN) ).to include( @mixin )
		end

		it "is not returned as one of the mixins to apply to an entry that is not a child of " +
		   "its base" do
			expect( Treequel::Model.mixins_for_dn(TEST_PERSON_DN) ).to_not include( @mixin )
		end

		it "can create a BranchCollection that will search for applicable entries"  do
			result = @mixin.search

			expect( result ).to be_a( Treequel::BranchCollection )
			expect( result.base_dns.length ).to eq( 2 )
			expect( result.base_dns ).to include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
			result.branchsets.each do |brset|
				expect( brset.filter_string ).to eq( '(objectClass=*)' )
				expect( brset.branch.directory ).to eq( @directory )
			end
		end

		it "can create a BranchCollection that will search for applicable entries in a Directory " +
		   " other than the one set for Treequel::Model"  do
			conn = double( "second ldap connection object" )
			directory = get_fixtured_directory( conn )

			result = @mixin.search( directory )

			expect( result ).to be_a( Treequel::BranchCollection )
			expect( result.base_dns.length ).to eq( 2 )
			expect( result.base_dns ).to include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
			result.branchsets.each do |brset|
				expect( brset.filter_string ).to eq( '(objectClass=*)' )
				expect( brset.branch.directory ).to eq( directory )
			end
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

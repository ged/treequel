#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/matchers'

require 'treequel/model'
require 'treequel/model/objectclass'
require 'treequel/branchset'


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Model::ObjectClass do
	include Treequel::SpecHelpers,
	        Treequel::Matchers

	class << self
		alias_method :they, :it
	end

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "outputs a warning when it is included instead of used to extend a Module" do
		Treequel::Model::ObjectClass.should_receive( :warn ).
			with( /extending.*rather than appending/i )
		mixin = Module.new do
			include Treequel::Model::ObjectClass
		end
	end


	describe "modules" do

		after( :each ) do
			Treequel::Model.objectclass_registry.clear
		end

		they "can declare a required objectClass" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end

			mixin.model_objectclasses.should == [:inetOrgPerson]
		end

		they "can declare multiple required objectClasses" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson, :acmeAccount
			end

			mixin.model_objectclasses.should == [ :inetOrgPerson, :acmeAccount ]
		end

		they "can declare a single base" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :device
				model_bases TEST_PHONES_DN
			end

			mixin.model_bases.should == [TEST_PHONES_DN]
		end

		they "can declare base with spaces" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :device
				model_bases 'ou=phones, dc=acme, dc=com'
			end

			mixin.model_bases.should == ['ou=phones,dc=acme,dc=com']
		end

		they "can declare multiple bases" do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :ipHost
				model_bases TEST_HOSTS_DN,
				            TEST_SUBHOSTS_DN
			end

			mixin.model_bases.should include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
		end

		they "raises an exception when creating a search for a mixin that hasn't declared " +
		     "at least one objectClass or base"  do
			mixin = Module.new do
				extend Treequel::Model::ObjectClass
			end

			expect {
				mixin.search( @directory )
			}.to raise_exception( Treequel::ModelError, /has no search criteria defined/ )
		end

	end

	describe "module that has one required objectClass declared" do

		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :inetOrgPerson
			end
		end

		after( :each ) do
			Treequel::Model.objectclass_registry.clear
		end


		it "is returned as one of the mixins for entries with only that objectClass" do
			Treequel::Model.mixins_for_objectclasses( :inetOrgPerson ).
				should include( @mixin )
		end

		it "is not returned in the list of mixins to apply to an entry without that objectClass" do
			Treequel::Model.mixins_for_objectclasses( :device ).
				should_not include( @mixin )
		end

		it "can set up a search for applicable entries given a Treequel::Directory to " +
		   "search"  do
			directory = mock( "Treequel directory", :registered_controls => [] )
			directory.should_receive( :base_dn ).and_return( TEST_BASE_DN )

			result = @mixin.search( directory )

			result.should be_a( Treequel::Branchset )
			result.base_dn.should == TEST_BASE_DN
			result.filter.to_s.should == '(objectClass=inetOrgPerson)'
		end

	end

	describe "module that has more than one required objectClass declared" do

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
			Treequel::Model.mixins_for_objectclasses( :device, :ipHost ).
				should include( @mixin )
		end

		it "is not returned in the list of mixins to apply to an entry with only one of its " +
		     "objectClasses" do
			Treequel::Model.mixins_for_objectclasses( :device ).
				should_not include( @mixin )
		end

		it "can set up a search for applicable entries given a Treequel::Directory to " +
		   "search"  do
			directory = mock( "Treequel directory", :registered_controls => [] )
			directory.should_receive( :base_dn ).and_return( TEST_BASE_DN )

			result = @mixin.search( directory )

			result.should be_a( Treequel::Branchset )
			result.base_dn.should == TEST_BASE_DN
			result.filter.to_s.should == '(&(objectClass=device)(objectClass=ipHost))'
		end

	end

	describe "module that has one base declared" do
		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_bases TEST_PEOPLE_DN
			end
		end

		after( :each ) do
			Treequel::Model.base_registry.clear
		end


		it "is returned as one of the mixins to apply to an entry that is a child of its base" do
			Treequel::Model.mixins_for_dn( TEST_PERSON_DN ).
				should include( @mixin )
		end

		it "is not returned as one of the mixins to apply to an entry that is not a child of " +
		   "its base" do
			Treequel::Model.mixins_for_dn( TEST_ROOM_DN ).
				should_not include( @mixin )
		end

		it "can set up a search for applicable entries given a Treequel::Directory to " +
		   "search"  do
			directory = stub( "Treequel directory", :registered_controls => [] )

			result = @mixin.search( directory )

			result.should be_a( Treequel::Branchset )
			result.base_dn.should == TEST_PEOPLE_DN
			result.filter.to_s.should == '(objectClass=*)'
		end

	end

	describe "module that has more than one base declared" do
		before( :each ) do
			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_bases TEST_HOSTS_DN,
				            TEST_SUBHOSTS_DN
			end
		end

		after( :each ) do
			Treequel::Model.base_registry.clear
		end


		it "is returned as one of the mixins to apply to an entry that is a child of one of " +
		   "its bases" do
			Treequel::Model.mixins_for_dn( TEST_SUBHOST_DN ).
				should include( @mixin )
		end

		it "is not returned as one of the mixins to apply to an entry that is not a child of " +
		   "its base" do
			Treequel::Model.mixins_for_dn( TEST_PERSON_DN ).
				should_not include( @mixin )
		end

		it "can set up a search for applicable entries given a Treequel::Directory to " +
		   "search"  do
			directory = stub( "Treequel directory", :registered_controls => [] )

			result = @mixin.search( directory )

			result.should be_a( Treequel::BranchCollection )
			result.base_dns.should have( 2 ).members
			result.base_dns.should include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
			result.branchsets.all? {|brset| brset.filter_string == '(objectClass=*)' }.
				should be_true()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

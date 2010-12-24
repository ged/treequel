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
require 'spec/lib/matchers'

require 'treequel/model'

include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Model do
	include Treequel::SpecHelpers,
	        Treequel::Matchers


	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@simple_entry = {
			'dn' => TEST_HOST_DN,
			'objectClass' => ['ipHost', 'device']
		}
		@conn = double( "LDAP connection", :set_option => true, :bound? => false )
		@directory = get_fixtured_directory( @conn )
	end

	after( :each ) do
		Treequel::Model.objectclass_registry.clear
		Treequel::Model.base_registry.clear
	end


	it "knows which mixins should be applied for a single objectClass" do
		mixin = Module.new
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson] )
		mixin.should_receive( :model_bases ).at_least( :once ).
			and_return( [] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.mixins_for_objectclasses( :inetOrgPerson ).should include( mixin )
	end

	it "knows which mixins should be applied for multiple objectClasses" do
		mixin = Module.new
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson, :organizationalPerson] )
		mixin.should_receive( :model_bases ).at_least( :once ).
			and_return( [] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.mixins_for_objectclasses( :inetOrgPerson, :organizationalPerson ).
			should include( mixin )
	end

	it "knows which mixins should be applied for a DN that exactly matches one that's registered" do
		mixin = Module.new
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [] )
		mixin.should_receive( :model_bases ).at_least( :once ).
			and_return( [TEST_PEOPLE_DN] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.mixins_for_dn( TEST_PEOPLE_DN ).should include( mixin )
	end

	it "knows which mixins should be applied for a DN that is a child of one that's registered" do
		mixin = mock( "module" )
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [] )
		mixin.should_receive( :model_bases ).at_least( :once ).
			and_return( [TEST_PEOPLE_DN] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.mixins_for_dn( TEST_PERSON_DN ).should include( mixin )
	end

	it "knows that mixins that don't have a base apply to all DNs" do
		mixin = mock( "module" )
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [:top] )
		mixin.should_receive( :model_bases ).at_least( :once ).and_return( [] )

		Treequel::Model.register_mixin( mixin )

		Treequel::Model.mixins_for_dn( TEST_PERSON_DN ).should include( mixin )
	end

	it "adds new registries to subclasses" do
		subclass = Class.new( Treequel::Model )

		# The registry should have the same default proc, but be a distinct Hash
		subclass.objectclass_registry.default_proc.
			should equal( Treequel::Model::SET_HASH.default_proc )
		subclass.objectclass_registry.should_not equal( Treequel::Model.objectclass_registry )

		# Same with this one
		subclass.base_registry.default_proc.
			should equal( Treequel::Model::SET_HASH.default_proc )
		subclass.base_registry.should_not equal( Treequel::Model.base_registry )
	end

	it "extends new instances with registered mixins which are applicable" do
		mixin1 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN, TEST_SUBHOSTS_DN
			model_objectclasses :ipHost
		end
		mixin2 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN
			model_objectclasses :device
		end
		mixin3 = Module.new do
			extend Treequel::Model::ObjectClass
			model_objectclasses :person
		end

		obj = Treequel::Model.new( @directory, TEST_SUBHOST_DN, @simple_entry )

		obj.should be_a( mixin1 )
		obj.should_not be_a( mixin2 )
		obj.should_not be_a( mixin3 )
	end

	it "extends new instances with mixins that are implied by objectClass SUP attributes, too" do
		inherited_mixin = Module.new do
			extend Treequel::Model::ObjectClass
			model_objectclasses :top
		end
		mixin1 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN, TEST_SUBHOSTS_DN
			model_objectclasses :ipHost
		end

		obj = Treequel::Model.new( @directory, TEST_SUBHOST_DN, @simple_entry )

		obj.should be_a( mixin1 )
		obj.should be_a( inherited_mixin )
	end

	it "applies applicable mixins to instances created before looking up the corresponding entry" do
		mixin1 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN, TEST_SUBHOSTS_DN
			model_objectclasses :ipHost
		end
		mixin2 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN
			model_objectclasses :device
		end
		mixin3 = Module.new do
			extend Treequel::Model::ObjectClass
			model_objectclasses :person
		end

		obj = Treequel::Model.new( @directory, TEST_HOST_DN )
		@directory.stub( :get_entry ).with( obj ).and_return( @simple_entry )
		obj.exists? # Trigger the lookup

		obj.should be_a( mixin1 )
		obj.should be_a( mixin2 )
		obj.should_not be_a( mixin3 )
	end

	it "doesn't try to apply objectclasses to non-existant entries" do
		mixin1 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN, TEST_SUBHOSTS_DN
			model_objectclasses :ipHost
		end

		@directory.stub( :get_entry ).and_return( nil )
		obj = Treequel::Model.new( @directory, TEST_HOST_DN )
		obj.exists? # Trigger the lookup

		obj.should_not be_a( mixin1 )
	end

	it "allows a mixin to be unregistered" do
		mixin = Module.new
		mixin.should_receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson] )
		mixin.should_receive( :model_bases ).at_least( :once ).
			and_return( [] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.unregister_mixin( mixin )
		Treequel::Model.mixins_for_objectclasses( :inetOrgPerson ).should_not include( mixin )
	end


	describe "created from DNs" do
		before( :all ) do
			@entry = {
				'dn'          => [TEST_PERSON_DN],
				'cn'          => ['Slappy the Frog'],
				'objectClass' => ['ipHost'],
			}
		end

		before( :each ) do
			Treequel::Model.objectclass_registry.clear
			Treequel::Model.base_registry.clear

			@mixin = Module.new do
				extend Treequel::Model::ObjectClass
				model_objectclasses :ipHost
				def fqdn; "some.home.example.com"; end
			end
			@obj = Treequel::Model.new( @directory, TEST_PERSON_DN )
		end

		it "correctly dispatches to methods added via extension that are called before its " +
		     "entry is loaded" do
			@directory.should_receive( :get_entry ).with( @obj ).at_least( :once ).and_return( @entry )
			@obj.fqdn.should == 'some.home.example.com'
		end

		it "correctly falls through for methods not added by loading the entry" do
			@directory.should_receive( :get_entry ).with( @obj ).and_return( @entry )
			@obj.cn.should == ['Slappy the Frog']
		end

	end


	describe "objects created from entries" do

		before( :all ) do
			@entry = {
				'dn'          => ['uid=slappy,ou=people,dc=acme,dc=com'],
				'uid'         => ['slappy'],
				'cn'          => ['Slappy the Frog'],
				'givenName'   => ['Slappy'],
				'sn'          => ['Frog'],
				'l'           => ['a forest in England'],
				'title'       => ['Forest Fire Prevention Advocate'],
				'displayName' => ['Slappy the Frog'],
				'logonTime'   => 'a time string',
				'objectClass' => %w[
					top
					person
					organizationalPerson
					inetOrgPerson
					posixAccount
					shadowAccount
					apple-user
				],
			}
		end

		before( :each ) do
			@obj = Treequel::Model.new_from_entry( @entry, @directory )
		end


		it "provides readers for valid attributes" do
			attrtype = stub( "Treequel attributeType object", :name => :uid )

			@obj.should_receive( :valid_attribute_type ).with( :uid ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :uid ).and_return( ['slappy'] )

			@obj.uid.should == ['slappy']
		end

		it "normalizes underbarred readers for camelCased attributes" do
			attrtype = stub( "Treequel attributeType object", :name => :givenName )

			@obj.should_receive( :valid_attribute_type ).with( :given_name ).and_return( nil )
			@obj.should_receive( :valid_attribute_type ).with( :givenName ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :givenName ).and_return( ['Slappy'] )

			@obj.given_name.should == ['Slappy']
		end

		it "falls through to branch-traversal for a reader with arguments" do
			@obj.should_not_receive( :valid_attribute_type )
			@obj.should_not_receive( :[] )

			@obj.should_receive( :traverse_branch ).
				with( :dc, :admin, {} ).and_return( :a_child_branch )

			@obj.dc( :admin ).should == :a_child_branch
		end

		it "accommodates branch-traversal from its auto-generated readers" do
			@obj.should_receive( :[] ).with( :uid ).and_return( ['slappy'] )
			@obj.uid.should == ['slappy']

			@obj.uid( :slappy ).should be_a( Treequel::Model )
		end

		it "provides writers for valid singular attributes" do
			attrtype = stub( "Treequel attributeType object", :name => :logonTime, :single? => true )

			@obj.should_receive( :valid_attribute_type ).with( :logonTime ).and_return( attrtype )
			@obj.should_receive( :[]= ).with( :logonTime, 'stampley' )

			@obj.logonTime = 'stampley'
		end

		it "provides writers for valid non-singular attributes that accept a non-array" do
			attrtype = stub( "Treequel attributeType object", :name => :uid, :single? => false )

			@obj.should_receive( :valid_attribute_type ).with( :uid ).and_return( attrtype )
			@obj.should_receive( :[]= ).with( :uid, ['stampley'] )

			@obj.uid = 'stampley'
		end

		it "provides a predicate that tests true for valid singular attributes that are set" do
			attrtype = stub( "Treequel attributeType object", :name => :activated, :single? => true )

			@obj.should_receive( :valid_attribute_type ).with( :activated ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :activated ).and_return( :a_time_object )

			@obj.should be_activated()
		end

		it "provides a predicate that tests false for valid singular attributes that are not set" do
			attrtype = stub( "Treequel attributeType object", :name => :deactivated, :single? => true )

			@obj.should_receive( :valid_attribute_type ).with( :deactivated ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :deactivated ).and_return( nil )

			@obj.should_not be_deactivated()
		end

		it "provides a predicate that tests true for valid non-singular attributes that have " +
		   "at least one value" do
			attrtype = stub( "Treequel attributeType object", :name => :description, :single? => false )

			@obj.should_receive( :valid_attribute_type ).with( :description ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :description ).
				and_return([ 'Racoon City', 'St-Michael Clock Tower' ])

			@obj.should have_description()
		end

		it "provides a predicate that tests false for valid non-singular attributes that don't " +
		   "have at least one value" do
			attrtype = stub( "Treequel attributeType object", :name => :l, :single? => false )

			@obj.should_receive( :valid_attribute_type ).with( :locality_name ).and_return( attrtype )
			@obj.should_receive( :[] ).with( :l ).
				and_return([])

			@obj.should_not have_locality_name()
		end

		it "falls through to the default proxy method for invalid attributes" do
			@obj.stub( :valid_attribute_type ).and_return( nil )
			@entry.should_not_receive( :[] )

			expect {
				@obj.nonexistant
			}.to raise_exception( NoMethodError, /undefined method/i )
		end

		it "adds the objectClass attribute to the attribute list when executing a search that " +
		   "contains a select" do
			@directory.stub( :convert_to_object ).and_return {|oid,str| str }
			@directory.should_receive( :search ).
				with( @obj, :scope, :filter, :selectattrs => ['cn', 'objectClass'] )
			@obj.search( :scope, :filter, :selectattrs => ['cn'] )
		end

		it "doesn't add the objectClass attribute to the attribute list when the search " +
		   "doesn't contain a select" do
			@directory.stub( :convert_to_object ).and_return {|oid,str| str }
			@directory.should_receive( :search ).
				with( @obj, :scope, :filter, :selectattrs => [] )
			@obj.search( :scope, :filter, :selectattrs => [] )
		end

		it "knows which attribute methods it responds to" do
			@directory.stub( :convert_to_object ).and_return {|oid,str| str }
			@obj.should respond_to( :cn )
			@obj.should_not respond_to( :humpsize )
		end

		it "defers writing modifications via #[]= back to the directory" do
			@conn.should_not_receive( :modify )
			@obj[ :uid ] = 'slippy'
			@obj.uid.should == ['slippy']
		end

		it "defers writing modifications via #merge back to the directory" do
			@conn.should_not_receive( :modify )
			@obj.merge( :uid => 'slippy', :givenName => 'Slippy' )
			@obj.uid.should == ['slippy']
			@obj.given_name.should == ['Slippy']
		end

		it "defers writing modifications via #delete back to the directory" do
			@conn.should_not_receive( :modify )
			@obj.delete( :uid, :givenName )
			@obj.uid.should == []
			@obj.given_name.should == []
		end


		context "with no modified attributes" do

			it "knows that it hasn't been modified" do
				@obj.should_not be_modified()
			end

			it "doesn't write anything to the directory when its #save method is called" do
				@conn.should_not_receive( :modify )
				@obj.save
			end

		end


		context "with a single modified attribute" do

			before( :each ) do
				@obj.uid = 'slippy'
			end

			it "knows that is has been modified" do
				@obj.should be_modified()
			end

			it "can return the modification as a list of LDAP::Mod objects" do
				result = @obj.modifications

				result.should be_an( Array )
				result.should have( 1 ).member
				result[0].should be_a( LDAP::Mod )
				result[0].mod_op.should == LDAP::LDAP_MOD_REPLACE
				result[0].mod_type.should == 'uid'
				result[0].mod_vals.should == ['slippy']
			end

			it "reverts the attribute if its #revert method is called" do
				@obj.revert
				@obj.uid.should == @entry['uid'].first
			end

		end


		context "with several modified attributes" do

			before( :each ) do
				@obj.uid = 'fappy'
				@obj.given_name = 'Fappy'
				@obj.display_name = 'Fappy the Bear'
			end

			it "knows that is has been modified" do
				@obj.should be_modified()
			end

			it "can return the modifications as a list of LDAP::Mod objects"

			it "reverts all of the attributes if its #revert method is called" do
				@obj.revert
				@obj.uid.should == @entry['uid'].first
				@obj.given_name.should == @entry['givenName'].first
				@obj.display_name.should == @entry['displayName'].first
			end

		end

	end

end


# vim: set nosta noet ts=4 sw=4:

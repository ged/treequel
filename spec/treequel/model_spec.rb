#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'
require 'spec/lib/helpers'
require 'treequel/model'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Model do

	before( :all ) do
		GC.disable
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
		GC.enable
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
		Treequel::Model.directory = nil
	end


	it "allows a Treequel::Directory object to be set as the default directory to use for searches" do
		Treequel::Model.directory = @directory
		@directory.results_class.should == Treequel::Model
	end

	it "can return a Treequel::Directory object configured to use the system directory if " +
	   "none has been set" do
		Treequel.should_receive( :directory_from_config ).and_return( @directory )
		Treequel::Model.directory.should == @directory
		@directory.results_class.should == Treequel::Model
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

	it "extends dups of new instances with registered mixins" do
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

		obj = Treequel::Model.new( @directory, TEST_SUBHOST_DN, @simple_entry ).dup

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

	it "applies applicable mixins to instances which have objectClasses added to them" do
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

		@conn.stub( :search_ext2 ).
			with( TEST_HOST_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
			and_return( [] )
		obj = Treequel::Model.new( @directory, TEST_HOST_DN )

		obj.extensions.should be_empty()

		obj.object_class += [ :ipHost ]
		obj.extensions.should have( 1 ).member
		obj.should be_a( mixin1 )
		obj.should_not be_a( mixin2 )

		obj.object_class += [ :device ]
		obj.extensions.should have( 2 ).members
		obj.should be_a( mixin1 )
		obj.should be_a( mixin2 )

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


	describe "created via attribute transition from their parent" do

		before( :each ) do
			@entry = TEST_HOSTS_ENTRY.dup
			@parent = Treequel::Model.new_from_entry( @entry, @directory )
		end


		it "has its RDN attributes set when it's a simple RDN" do
			@conn.stub( :search_ext2 ).
				with( "cn=wafflebreaker,#{TEST_HOSTS_DN}", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)").
				and_return( [] )

			host = @parent.cn( :wafflebreaker )
			host.object_class = :ipHost
			host.cn.should == ['wafflebreaker']
		end

		it "has its RDN attributes set when it's a multi-value RDN" do
			@conn.stub( :search_ext2 ).
				with( "cn=wiffle+l=downtown,#{TEST_HOSTS_DN}", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)").
				and_return( [] )

			host = @parent.cn( :wiffle, :l => 'downtown' )
			host.object_class = :ipHost

			host.cn.should == ['wiffle']
			host.l.should == ['downtown']
		end
	end

	describe "objects loaded from entries" do

		before( :each ) do
			@entry = TEST_PERSON_ENTRY.dup
			@obj = Treequel::Model.new_from_entry( @entry, @directory )
		end


		it "provides readers for valid attributes" do
			@obj.uid.should == ['slappy']
		end

		it "provides readers for single-letter attributes" do
			@obj.l.should == ['a forest in England']
		end

		it "normalizes underbarred readers for camelCased attributes" do
			@obj.given_name.should == ['Slappy']
		end

		it "falls through to branch-traversal for a reader with arguments" do
			result = @obj.dc( :admin )
			result.should be_a( Treequel::Model )
			result.dn.should == "dc=admin,#{@entry['dn'].first}"
		end

		it "accommodates branch-traversal from its auto-generated readers" do
			@obj.uid # Generate the reader, which should then do traversal, too
			@obj.uid( :slappy ).should be_a( Treequel::Model )
		end

		it "provides writers for valid singular attributes" do
			@obj.logonTime.should == 1293167318
		end

		it "provides writers for valid non-singular attributes that accept a non-array" do
			@obj.uid = 'stampley'
			@obj.uid.should == ['stampley']
		end

		it "provides a predicate that tests true for valid singular attributes that are set" do
			@obj.display_name?.should be_true()
		end

		it "provides a predicate that tests false for valid singular attributes that are not set" do
			@obj.delete( :displayName )
			@obj.display_name?.should be_false()
		end

		it "provides a predicate that tests true for valid non-singular attributes that have " +
		   "at least one value" do
			@obj.should have_given_name()
		end

		it "provides a predicate that tests true for single-letter non-singular attributes " +
		   "that have at least one value" do
			@obj.should have_l()
		end

		it "provides a predicate that tests false for valid non-singular attributes that don't " +
		   "have at least one value" do
			@obj.delete( :givenName )
			@obj.should_not have_given_name()
		end

		it "falls through to the default proxy method for invalid attributes" do
			expect {
				@obj.nonexistant
			}.to raise_exception( NoMethodError, /undefined method/i )
		end

		it "adds the objectClass attribute to the attribute list when executing a search that " +
		   "contains a select" do
			@conn.should_receive( :search_ext2 ).
			 	with( @entry['dn'].first, LDAP::LDAP_SCOPE_ONELEVEL, "(cn=magnelion)",
			          ["cn", "objectClass"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return( [] )
			@obj.search( :one, '(cn=magnelion)', :selectattrs => ['cn'] )
		end

		it "doesn't add the objectClass attribute to the attribute list when the search " +
		   "doesn't contain a select" do
			@conn.should_receive( :search_ext2 ).
			 	with( @entry['dn'].first, LDAP::LDAP_SCOPE_ONELEVEL, "(cn=ephelion)",
			          ['*'], false, nil, nil, 0, 0, 0, "", nil ).
				and_return( [] )
			@obj.search( :one, '(cn=ephelion)' )
		end

		it "knows which attribute methods it responds to" do
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

		it "knows if any validation errors have been encountered" do
			@obj.errors.should be_a( Treequel::Model::Errors )
		end

		it "can delete its entry with callbacks" do
			class << @obj; attr_reader :callbacks; end
			@obj.instance_variable_set( :@callbacks, [] )
			def @obj.before_destroy
				self.callbacks << :before_destroy
			end
			def @obj.after_destroy
				self.callbacks << :after_destroy
			end

			@conn.should_receive( :delete ).with( @obj.dn )

			@obj.destroy
			@obj.callbacks.should == [ :before_destroy, :after_destroy ]
		end

		it "doesn't delete its entry if the destroy callback returns something falseish" do
			def @obj.before_destroy
				false
			end
			def @obj.after_destroy
				fail "shouldn't call the after_destroy hook, either"
			end

			@conn.should_not_receive( :delete )

			expect {
				@obj.destroy
			}.to raise_error( Treequel::BeforeHookFailed, /destroy/i )
		end

		it "doesn't raise a BeforeHookFailed if destroyed without :raise_on_failure" do
			def @obj.before_destroy
				false
			end

			@conn.should_not_receive( :delete )

			result = nil
			expect {
				result = @obj.destroy( :raise_on_failure => false )
			}.to_not raise_error()

			result.should be_false()
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
				result.should have( 1 ).members
				result.should include( ldap_mod_replace 'uid', 'slappy', 'slippy' )
			end

			it "reverts the attribute if its #revert method is called" do
				@conn.should_receive( :search_ext2 ).
					with( @entry['dn'].first, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry.dup ])

				@obj.revert

				@obj.uid.should == @entry['uid']
				@obj.should_not be_modified()
			end

			it "updates the modified attribute when saved" do
				@conn.should_receive( :modify ).
					with( TEST_PERSON_DN, [ldap_mod_replace(:uid, 'slappy', 'slippy')] )
				@obj.save
			end


			it "calls update hooks when saved" do
				class << @obj; attr_reader :callbacks; end
				@obj.instance_variable_set( :@callbacks, [] )
				def @obj.before_update( mods )
					self.callbacks << :before_update
				end
				def @obj.after_update( mods )
					self.callbacks << :after_update
				end

				@conn.should_receive( :modify )

				@obj.save
				@obj.callbacks.should == [ :before_update, :after_update ]
			end

			it "doesn't modify its entry if the before_update callback returns something falseish" do
				def @obj.before_update( mods )
					false
				end
				def @obj.after_update( mods )
					fail "shouldn't call the after_update hook, either"
				end

				@conn.should_not_receive( :modify )

				expect {
					@obj.save
				}.to raise_error( Treequel::BeforeHookFailed, /update/i )
			end

			it "doesn't raise a BeforeHookFailed if saved without :raise_on_failure" do
				def @obj.before_update( mods )
					false
				end

				@conn.stub( :search_ext2 ).with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return( [] )
				@conn.should_not_receive( :modify )

				result = nil
				expect {
					result = @obj.save( :raise_on_failure => false )
				}.to_not raise_error()

				result.should be_false()
			end
		end


		context "with several modified attributes" do

			before( :each ) do
				@obj.uid = 'fappy'
				@obj.given_name = 'Fappy'
				@obj.display_name = 'Fappy the Bear'
				@obj.delete( :l )
				@obj.delete( :description => 'Alright.' )
				@obj.description << "The new mascot."
			end

			it "knows that is has been modified" do
				@obj.should be_modified()
			end

			it "returns the modified values via its accessors" do
				@obj.uid.should == ['fappy']
				@obj.given_name.should == ['Fappy']
				@obj.display_name.should == 'Fappy the Bear' # SINGLE
				@obj.l.should == []
				@obj.description.should have( 2 ).members
				@obj.description.should include(
					"Smokey the Bear is much more intense in person.",
					"The new mascot."
				  )
			end

			it "can return the modifications as a list of LDAP::Mod objects" do
				result = @obj.modifications

				result.should be_an( Array )
				result.should have( 6 ).members
				result.should include( ldap_mod_replace :uid, 'slappy', 'fappy' )
				result.should include( ldap_mod_replace :givenName, 'Slappy', 'Fappy' )
				result.should include( ldap_mod_replace :displayName, 'Slappy the Frog',
				                       'Fappy the Bear' )
				result.should include( ldap_mod_delete :description, 'Alright.' )
				result.should include( ldap_mod_add :description, 'The new mascot.' )
				result.should include( ldap_mod_delete :l, 'a forest in England' )

			end

			it "reverts all of the attributes if its #revert method is called" do
				@conn.should_receive( :search_ext2 ).
					with( @entry['dn'].first, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry.dup ])

				@obj.revert

				@obj.uid.should == @entry['uid']
				@obj.given_name.should == @entry['givenName']
				@obj.display_name.should == @entry['displayName'].first # SINGLE
				@obj.l.should == @entry['l']
				@obj.should_not be_modified()
			end

		end

	end

	describe "objects created in memory" do

		before( :all ) do
			@entry = {
				'uid'           => ['jrandom'],
				'cn'            => ['James'],
				'sn'            => ['Hacker'],
				'l'             => ['a forest in England'],
				'displayName'   => ['J. Random Hacker'],
				'uidNumber'     => ['1121'],
				'gidNumber'     => ['200'],
				'homeDirectory' => ['/u/j/jrandom'],
				'objectClass'   => %w[
					person
					inetOrgPerson
					posixAccount
				],
			}
		end

		before( :each ) do
			@obj = Treequel::Model.new( @directory, TEST_PERSON_DN, @entry )
		end


		it "creates the entry in the directory when saved" do
			@conn.stub( :search_ext2 ).
				with( @obj.dn, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)').
				and_return( [] )

			@conn.should_receive( :add ).
				with( @obj.dn, [
					ldap_mod_add("cn", "James"),
					ldap_mod_add("displayName", "J. Random Hacker"),
					ldap_mod_add("gidNumber", "200"),
					ldap_mod_add("homeDirectory", "/u/j/jrandom"),
					ldap_mod_add("l", "a forest in England"),
					ldap_mod_add("objectClass", "inetOrgPerson"),
					ldap_mod_add("objectClass", "person"),
					ldap_mod_add("objectClass", "posixAccount"),
					ldap_mod_add("sn", "Hacker"),
					ldap_mod_add("uid", "jrandom"),
					ldap_mod_add("uidNumber", "1121")
				] )

			@obj.save
		end

		it "calls creation hooks when saved" do
			class << @obj; attr_reader :callbacks; end
			@obj.instance_variable_set( :@callbacks, [] )
			def @obj.before_create( mods )
				self.callbacks << :before_create
			end
			def @obj.after_create( mods )
				self.callbacks << :after_create
			end

			@conn.stub( :search_ext2 ).with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return( [] )
			@conn.should_receive( :add )

			@obj.save
			@obj.callbacks.should == [ :before_create, :after_create ]
		end

		it "doesn't add its entry if the before_create callback returns something falseish" do
			def @obj.before_create( mods )
				false
			end
			def @obj.after_create( mods )
				fail "shouldn't call the after_create hook, either"
			end

			@conn.stub( :search_ext2 ).with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return( [] )
			@conn.should_not_receive( :add )

			expect {
				@obj.save
			}.to raise_error( Treequel::BeforeHookFailed, /create/i )
		end

		it "doesn't raise a BeforeHookFailed if saved without :raise_on_failure" do
			def @obj.before_create( mods )
				false
			end

			@conn.stub( :search_ext2 ).with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return( [] )
			@conn.should_not_receive( :add )

			result = nil
			expect {
				result = @obj.save( :raise_on_failure => false )
			}.to_not raise_error()

			result.should be_false()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

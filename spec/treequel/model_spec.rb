# -*- ruby -*-
#encoding: utf-8

require_relative '../spec_helpers'
require 'treequel/model'

describe Treequel::Model do

	before( :all ) do
		GC.disable
	end

	after( :all ) do
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
		expect( @directory.results_class ).to eq( Treequel::Model )
	end

	it "can return a Treequel::Directory object configured to use the system directory if " +
	   "none has been set" do
		expect( Treequel ).to receive( :directory_from_config ).and_return( @directory )
		expect( Treequel::Model.directory ).to eq( @directory )
		expect( @directory.results_class ).to eq( Treequel::Model )
	end

	it "knows which mixins should be applied for a single objectClass" do
		mixin = Module.new
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).
			and_return( [] )

		Treequel::Model.register_mixin( mixin )
		expect( Treequel::Model.mixins_for_objectclasses( :inetOrgPerson ) ).to include( mixin )
	end

	it "knows which mixins should be applied for multiple objectClasses" do
		mixin = Module.new
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson, :organizationalPerson] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).
			and_return( [] )

		Treequel::Model.register_mixin( mixin )
		oc_mixins = Treequel::Model.mixins_for_objectclasses( :inetOrgPerson, :organizationalPerson )
		expect( oc_mixins ).to include( mixin )
	end

	it "knows which mixins should be applied for a DN that exactly matches one that's registered" do
		mixin = Module.new
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).
			and_return( [TEST_PEOPLE_DN] )

		Treequel::Model.register_mixin( mixin )
		expect( Treequel::Model.mixins_for_dn( TEST_PEOPLE_DN ) ).to include( mixin )
	end

	it "knows which mixins should be applied for a DN that is a child of one that's registered" do
		mixin = double( "module" )
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).
			and_return( [TEST_PEOPLE_DN] )

		Treequel::Model.register_mixin( mixin )
		expect( Treequel::Model.mixins_for_dn( TEST_PERSON_DN ) ).to include( mixin )
	end

	it "knows that mixins that don't have a base apply to all DNs" do
		mixin = double( "module" )
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [:top] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).and_return( [] )

		Treequel::Model.register_mixin( mixin )
		expect( Treequel::Model.mixins_for_dn( TEST_PERSON_DN ) ).to include( mixin )
	end

	it "adds new registries to subclasses" do
		subclass = Class.new( Treequel::Model )

		# The registry should have the same default proc, but be a distinct Hash
		expect( subclass.objectclass_registry.default_proc ).to equal( Treequel::Model::SET_HASH.default_proc )
		expect( subclass.objectclass_registry ).to_not equal( Treequel::Model.objectclass_registry )

		# Same with this one
		expect( subclass.base_registry.default_proc ).to equal( Treequel::Model::SET_HASH.default_proc )
		expect( subclass.base_registry ).to_not equal( Treequel::Model.base_registry )
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

		expect( obj ).to be_a( mixin1 )
		expect( obj ).to_not be_a( mixin2 )
		expect( obj ).to_not be_a( mixin3 )
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

		expect( obj ).to be_a( mixin1 )
		expect( obj ).to_not be_a( mixin2 )
		expect( obj ).to_not be_a( mixin3 )
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

		expect( obj ).to be_a( mixin1 )
		expect( obj ).to be_a( inherited_mixin )
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
		expect( @directory ).to receive( :get_entry ).with( obj ).and_return( @simple_entry )
		obj.exists? # Trigger the lookup

		expect( obj ).to be_a( mixin1 )
		expect( obj ).to be_a( mixin2 )
		expect( obj ).to_not be_a( mixin3 )
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

		expect( @conn ).to receive( :search_ext2 ).
			with( TEST_HOST_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
			at_least( :once ).
			and_return( [] )
		obj = Treequel::Model.new( @directory, TEST_HOST_DN )

		expect( obj.extensions ).to be_empty()

		obj.object_class += [ :ipHost ]
		expect( obj.extensions.length ).to eq( 1 )
		expect( obj ).to be_a( mixin1 )
		expect( obj ).to_not be_a( mixin2 )

		obj.object_class += [ :device ]
		expect( obj.extensions.length ).to eq( 2 )
		expect( obj ).to be_a( mixin1 )
		expect( obj ).to be_a( mixin2 )

	end

	it "doesn't try to apply objectclasses to non-existant entries" do
		mixin1 = Module.new do
			extend Treequel::Model::ObjectClass
			model_bases TEST_HOSTS_DN, TEST_SUBHOSTS_DN
			model_objectclasses :ipHost
		end

		expect( @directory ).to receive( :get_entry ).and_return( nil )
		obj = Treequel::Model.new( @directory, TEST_HOST_DN )
		obj.exists? # Trigger the lookup

		expect( obj ).to_not be_a( mixin1 )
	end

	it "allows a mixin to be unregistered" do
		mixin = Module.new
		expect( mixin ).to receive( :model_objectclasses ).at_least( :once ).
			and_return( [:inetOrgPerson] )
		expect( mixin ).to receive( :model_bases ).at_least( :once ).
			and_return( [] )
		Treequel::Model.register_mixin( mixin )
		Treequel::Model.unregister_mixin( mixin )
		expect( Treequel::Model.mixins_for_objectclasses( :inetOrgPerson ) ).to_not include( mixin )
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
				def self::extended( obj )
					Loggability[ Treequel::Model ].debug "Extending %p with %p" % [ obj, self ]
					super
				end
			end
			@obj = Treequel::Model.new( @directory, TEST_PERSON_DN )
		end

		it "correctly dispatches to methods added via extension that are called before its " +
		     "entry is loaded" do
			expect( @directory ).to receive( :get_entry ).with( @obj ).at_least( :once ).and_return( @entry )
			expect( @obj.fqdn ).to eq( 'some.home.example.com' )
		end

		it "correctly falls through for methods not added by loading the entry" do
			expect( @directory ).to receive( :get_entry ).with( @obj ).and_return( @entry )
			expect( @obj.cn ).to eq( ['Slappy the Frog'] )
		end

	end


	describe "created via attribute transition from their parent" do

		before( :each ) do
			@entry = TEST_HOSTS_ENTRY.dup
			@parent = Treequel::Model.new_from_entry( @entry, @directory )
		end


		it "has its RDN attributes set when it's a simple RDN" do
			expect( @conn ).to receive( :search_ext2 ).
				with( "cn=wafflebreaker,#{TEST_HOSTS_DN}", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)").
				at_least( :once ).
				and_return( [] )

			host = @parent.cn( :wafflebreaker )
			host.object_class = :ipHost
			expect( host.cn ).to eq( ['wafflebreaker'] )
		end

		it "has its RDN attributes set when it's a multi-value RDN" do
			expect( @conn ).to receive( :search_ext2 ).
				with( "cn=wiffle+l=downtown,#{TEST_HOSTS_DN}", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)").
				at_least( :once ).
				and_return( [] )

			host = @parent.cn( :wiffle, :l => 'downtown' )
			host.object_class = :ipHost

			expect( host.cn ).to eq( ['wiffle'] )
			expect( host.l ).to eq( ['downtown'] )
		end
	end

	describe "objects loaded from entries" do

		before( :each ) do
			@entry = TEST_PERSON_ENTRY.dup
			@obj = Treequel::Model.new_from_entry( @entry, @directory )
		end


		it "provides readers for valid attributes" do
			expect( @obj.uid ).to eq( ['slappy'] )
		end

		it "provides readers for single-letter attributes" do
			expect( @obj.l ).to eq( ['a forest in England'] )
		end

		it "normalizes underbarred readers for camelCased attributes" do
			expect( @obj.given_name ).to eq( ['Slappy'] )
		end

		it "falls through to branch-traversal for a reader with arguments" do
			result = @obj.dc( :admin )
			expect( result ).to be_a( Treequel::Model )
			expect( result.dn ).to eq( "dc=admin,#{@entry['dn'].first}" )
		end

		it "accommodates branch-traversal from its auto-generated readers" do
			@obj.uid # Generate the reader, which should then do traversal, too
			expect( @obj.uid( :slappy ) ).to be_a( Treequel::Model )
		end

		it "provides writers for valid singular attributes" do
			expect( @obj.logonTime ).to eq( 1293167318 )
		end

		it "provides writers for valid non-singular attributes that accept a non-array" do
			@obj.uid = 'stampley'
			expect( @obj.uid ).to eq( ['stampley'] )
		end

		it "treats setting an attribute to nil as a delete" do
			@obj.display_name = 'J. P. Havershaven'
			expect( @obj.values ).to include( :displayName )
			@obj.display_name = nil
			expect( @obj.values ).to_not include( :displayName )
		end

		it "allows a BOOLEAN attribute to be set to false" do
			@obj.object_class += ['sambaAccount']
			@obj.rid = 1181
			@obj.pwd_must_change = false
			expect( @obj.values ).to include( :pwdMustChange => false )
			@obj.pwd_must_change = nil
			expect( @obj.values ).to_not include( :pwdMustChange )
		end

		it "provides a predicate that tests true for valid singular attributes that are set" do
			expect( @obj.display_name? ).to be_truthy()
		end

		it "provides a predicate that tests false for valid singular attributes that are not set" do
			@obj.delete( :displayName )
			expect( @obj.display_name? ).to be_falsey()
		end

		it "provides a predicate that tests true for valid non-singular attributes that have " +
		   "at least one value", log: :debug do
			# pending "implementation of Model#respond_to_missing? :mahlon:"
			expect( @obj ).to have_given_name()
		end

		it "provides a predicate that tests true for single-letter non-singular attributes " +
		   "that have at least one value" do
			# pending "implementation of Model#respond_to_missing? :mahlon:"
			expect( @obj ).to have_l()
		end

		it "provides a predicate that tests false for valid non-singular attributes that don't " +
		   "have at least one value" do
			# pending "implementation of Model#respond_to_missing? :mahlon:"
			@obj.delete( :givenName )
			expect( @obj ).to_not have_given_name()
		end

		it "falls through to the default proxy method for invalid attributes" do
			expect {
				@obj.nonexistant
			}.to raise_exception( NoMethodError, /undefined method/i )
		end

		it "adds the objectClass attribute to the attribute list when executing a search that " +
		   "contains a select" do
			expect( @conn ).to receive( :search_ext2 ).
				with( @entry['dn'].first, LDAP::LDAP_SCOPE_ONELEVEL, "(cn=magnelion)",
			          ["cn", "objectClass"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return( [] )
			@obj.search( :one, '(cn=magnelion)', :selectattrs => ['cn'] )
		end

		it "doesn't add the objectClass attribute to the attribute list when the search " +
		   "doesn't contain a select" do
			expect( @conn ).to receive( :search_ext2 ).
				with( @entry['dn'].first, LDAP::LDAP_SCOPE_ONELEVEL, "(cn=ephelion)",
			          ['*'], false, nil, nil, 0, 0, 0, "", nil ).
				and_return( [] )
			@obj.search( :one, '(cn=ephelion)' )
		end

		it "knows which attribute methods it responds to" do
			expect( @obj ).to respond_to( :cn )
			expect( @obj ).to_not respond_to( :humpsize )
		end

		it "defers writing modifications via #[]= back to the directory" do
			expect( @conn ).to_not receive( :modify )
			@obj[ :uid ] = 'slippy'
			expect( @obj.uid ).to eq( ['slippy'] )
		end

		it "defers writing modifications via #merge back to the directory" do
			expect( @conn ).to_not receive( :modify )
			@obj.merge( :uid => 'slippy', :givenName => 'Slippy' )
			expect( @obj.uid ).to eq( ['slippy'] )
			expect( @obj.given_name ).to eq( ['Slippy'] )
		end

		it "defers writing modifications via #delete back to the directory" do
			expect( @conn ).to_not receive( :modify )
			@obj.delete( :uid, :givenName )
			expect( @obj.uid ).to eq( [] )
			expect( @obj.given_name ).to eq( [] )
		end

		it "knows if any validation errors have been encountered" do
			expect( @obj.errors ).to be_a( Treequel::Model::Errors )
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

			expect( @conn ).to receive( :delete ).with( @obj.dn )

			@obj.destroy
			expect( @obj.callbacks ).to eq( [ :before_destroy, :after_destroy ] )
		end

		it "doesn't delete its entry if the destroy callback returns something falseish" do
			def @obj.before_destroy
				false
			end
			def @obj.after_destroy
				fail "shouldn't call the after_destroy hook, either"
			end

			expect( @conn ).to_not receive( :delete )

			expect {
				@obj.destroy
			}.to raise_error( Treequel::BeforeHookFailed, /destroy/i )
		end

		it "doesn't raise a BeforeHookFailed if destroyed without :raise_on_failure" do
			def @obj.before_destroy
				false
			end

			expect( @conn ).to_not receive( :delete )

			result = nil
			expect {
				result = @obj.destroy( :raise_on_failure => false )
			}.to_not raise_error()

			expect( result ).to be_falsey()
		end


		context "with no modified attributes" do

			it "knows that it hasn't been modified" do
				expect( @obj ).to_not be_modified()
			end

			it "doesn't write anything to the directory when its #save method is called" do
				expect( @conn ).to_not receive( :modify )
				@obj.save
			end

		end


		context "with a single modified attribute" do

			before( :each ) do
				@obj.uid = 'slippy'
			end

			it "knows that is has been modified" do
				expect( @obj ).to be_modified()
			end

			it "can return the modification as a list of LDAP::Mod objects" do
				result = @obj.modifications

				expect( result ).to be_an( Array )
				expect( result.length ).to eq( 1 )
				expect( result ).to include( ldap_mod_replace 'uid', 'slippy' )
			end

			it "reverts the attribute if its #revert method is called" do
				expect( @conn ).to receive( :search_ext2 ).
					with( @entry['dn'].first, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry.dup ])

				@obj.revert

				expect( @obj.uid ).to eq( @entry['uid'] )
				expect( @obj ).to_not be_modified()
			end

			it "updates the modified attribute when saved" do
				expect( @conn ).to receive( :modify ).
					with( TEST_PERSON_DN, [ldap_mod_replace(:uid, 'slippy')] )
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

				expect( @conn ).to receive( :modify )

				@obj.save
				expect( @obj.callbacks ).to eq( [ :before_update, :after_update ] )
			end

			it "doesn't modify its entry if the before_update callback returns something falseish" do
				def @obj.before_update( mods )
					false
				end
				def @obj.after_update( mods )
					fail "shouldn't call the after_update hook, either"
				end

				expect( @conn ).to_not receive( :modify )

				expect {
					@obj.save
				}.to raise_error( Treequel::BeforeHookFailed, /update/i )
			end

			it "doesn't raise a BeforeHookFailed if saved without :raise_on_failure" do
				def @obj.before_update( mods )
					false
				end

				allow( @conn ).to receive( :search_ext2 ).
					with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return( [] )
				expect( @conn ).to_not receive( :modify )

				result = nil
				expect {
					result = @obj.save( :raise_on_failure => false )
				}.to_not raise_error()

				expect( result ).to be_falsey()
			end

			it "doesn't validate the model if saved with :validate set to false" do
				allow( @conn ).to receive( :search_ext2 ).
					with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return( [] )
				expect( @conn ).to receive( :modify )
				expect( @obj ).to_not receive( :valid? )

				expect {
					result = @obj.save( :validate => false )
				}.to_not raise_error()
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
				expect( @obj ).to be_modified()
			end

			it "returns the modified values via its accessors" do
				expect( @obj.uid ).to eq( ['fappy'] )
				expect( @obj.given_name ).to eq( ['Fappy'] )
				expect( @obj.display_name ).to eq( 'Fappy the Bear' ) # SINGLE
				expect( @obj.l ).to eq( [] )
				expect( @obj.description.length ).to eq( 2 )
				expect( @obj.description ).to include(
					"Smokey the Bear is much more intense in person.",
					"The new mascot."
				  )
			end

			it "can return the modifications as a list of LDAP::Mod objects" do
				result = @obj.modifications

				expect( result ).to be_an( Array )
				expect( result ).to include( ldap_mod_replace :uid, 'fappy' )
				expect( result ).to include( ldap_mod_replace :givenName, 'Fappy' )
				expect( result ).to include( ldap_mod_replace :displayName, 'Fappy the Bear' )
				expect( result ).to include( ldap_mod_replace :description,
					'Smokey the Bear is much more intense in person.', 'The new mascot.' )
				expect( result ).to include( ldap_mod_delete :l )
			end

			it "reverts all of the attributes if its #revert method is called" do
				expect( @conn ).to receive( :search_ext2 ).
					with( @entry['dn'].first, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry.dup ])

				@obj.revert

				expect( @obj.uid ).to eq( @entry['uid'] )
				expect( @obj.given_name ).to eq( @entry['givenName'] )
				expect( @obj.display_name ).to eq( @entry['displayName'].first ) # SINGLE
				expect( @obj.l ).to eq( @entry['l'] )
				expect( @obj ).to_not be_modified()
			end

			it "doesn't try to mistakenly delete an attribute that's assigned an empty array " +
			"and isn't set in the directory" do
				@obj.secretary = []
				result = @obj.modifications
				expect( result ).to_not include( ldap_mod_delete :secretary )
			end

		end

		it "avoids Arrayifying Time objects when converting them to generalized time strings" do
			entry = {
				'dn' => ["cn=something,#{TEST_BASE_DN}"],
				'objectClass' => ['dhcpLeases'],
				'cn' => ['something'],
				'dhcpAddressState' => ['ACTIVE'],
			}
			obj = Treequel::Model.new_from_entry( entry, @directory )

			obj.dhcp_start_time_of_state = Time.utc( 1322607981 )

			expect( obj.modifications ).to include( ldap_mod_add :dhcpStartTimeOfState, '13226079810101000000Z' )
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
			expect( @conn ).to receive( :search_ext2 ).
				with( @obj.dn, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)').
				at_least( :once ).
				and_return( [] )

			expect( @conn ).to receive( :add ).
				with( @obj.dn, [
					ldap_mod_add( :cn, "James" ),
					ldap_mod_add( :displayName, "J. Random Hacker" ),
					ldap_mod_add( :gidNumber, "200" ),
					ldap_mod_add( :homeDirectory, "/u/j/jrandom" ),
					ldap_mod_add( :l, "a forest in England" ),
					ldap_mod_add( :objectClass, "person", "inetOrgPerson", "posixAccount" ),
					ldap_mod_add( :sn, "Hacker" ),
					ldap_mod_add( :uid, "jrandom" ),
					ldap_mod_add( :uidNumber, "1121" ),
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

			expect( @conn ).to receive( :search_ext2 ).
				with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				at_least( :once ).
				and_return( [] )
			expect( @conn ).to receive( :add )

			@obj.save
			expect( @obj.callbacks ).to eq( [ :before_create, :after_create ] )
		end

		it "doesn't add its entry if the before_create callback returns something falseish" do
			def @obj.before_create( mods )
				false
			end
			def @obj.after_create( mods )
				fail "shouldn't call the after_create hook, either"
			end

			expect( @conn ).to receive( :search_ext2 ).
				with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				at_least( :once ).
				and_return( [] )
			expect( @conn ).to_not receive( :add )

			expect {
				@obj.save
			}.to raise_error( Treequel::BeforeHookFailed, /create/i )
		end

		it "doesn't raise a BeforeHookFailed if saved without :raise_on_failure" do
			def @obj.before_create( mods )
				false
			end

			expect( @conn ).to receive( :search_ext2 ).
				with( @obj.dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				at_least( :once ).
				and_return( [] )
			expect( @conn ).to_not receive( :add )

			result = nil
			expect {
				result = @obj.save( :raise_on_failure => false )
			}.to_not raise_error()

			expect( result ).to be_falsey()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

# -*- ruby -*-
#encoding: utf-8

require_relative '../spec_helpers'

require 'treequel/directory'
require 'treequel/branch'
require 'treequel/control'


describe Treequel::Directory do
	include Treequel::SpecHelpers


	before( :each ) do
		@options = {
			:host         => TEST_HOST,
			:port         => TEST_PORT,
			:base_dn      => TEST_BASE_DN,
			:connect_type => :plain,
		}
		@conn = double( "LDAP connection", :set_option => true, :bound? => false )
		allow( LDAP::SSLConn ).to receive( :new ).and_return( @conn )

		allow( @conn ).to receive( :schema ).and_return( SCHEMAHASH )
	end


	it "is created with reasonable default options if none are specified" do
		expect( @conn ).to receive( :search_ext2 ).
			with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
			and_return( TEST_DSE )

		dir = Treequel::Directory.new

		expect( dir.host ).to eq( 'localhost' )
		expect( dir.port ).to eq( 389 )
		expect( dir.connect_type ).to eq( :tls )
		expect( dir.base_dn ).to eq( 'dc=acme,dc=com' )
	end

	it "is created with the specified options if options are specified" do
		dir = Treequel::Directory.new( @options )

		expect( dir.host ).to eq( TEST_HOST )
		expect( dir.port ).to eq( TEST_PORT )
		expect( dir.connect_type ).to eq( @options[:connect_type] )
		expect( dir.base_dn ).to eq( TEST_BASE_DN )
	end

	it "binds immediately if user/pass is included in the ldap URI" do
		conn = double( "LDAP connection", :set_option => true )

		expect( LDAP::Conn ).to receive( :new ).with( TEST_HOST, TEST_PORT ).
			and_return( conn )
		expect( conn ).to receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )

		dir = Treequel::Directory.new( @options.merge(:bind_dn => TEST_BIND_DN, :pass => TEST_BIND_PASS) )
		expect( dir.bound_user ).to eq( TEST_BIND_DN )
	end

	it "uses the first namingContext from the Root DSE if no base is specified" do
		expect( LDAP::Conn ).to receive( :new ).and_return( @conn )
		expect( @conn ).to receive( :search_ext2 ).
			with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
			and_return( TEST_DSE )

		dir = Treequel::Directory.new( @options.merge(:base_dn => nil) )
		expect( dir.base_dn ).to eq( TEST_BASE_DN )
	end

	it "can return its root element as a Branch instance" do
		dir = Treequel::Directory.new( @options )
		expect( dir.base ).to be_a( Treequel::Branch )
		expect( dir.base.dn ).to eq( TEST_BASE_DN )
	end

	it "can return its root element as an instance of its results class if it's been set" do
		subtype = Class.new( Treequel::Branch )
		dir = Treequel::Directory.new( @options )

		dir.results_class = subtype

		expect( dir.base ).to be_a( subtype )
		expect( dir.base.dn ).to eq( TEST_BASE_DN )
	end


	describe "instances without existing connections" do

		before( :each ) do
			@conn = double( "ldap connection", :bound? => false, :set_option => true )
			@dir = Treequel::Directory.new( @options )
		end


		it "stringifies as a description which includes the host, port, connection type and base" do
			expect( @dir.to_s ).to match( /#{Regexp.quote(TEST_HOST)}/ )
			expect( @dir.to_s ).to match( /#{TEST_PORT}/ )
			expect( @dir.to_s ).to match( /\b#{@dir.connect_type}\b/ )
			expect( @dir.to_s ).to match( /#{TEST_BASE_DN}/i )
		end

		it "connects on demand to the configured directory server" do
			expect( LDAP::Conn ).to receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( @conn )
			expect( @dir.conn ).to eq( @conn )
		end

		it "connects with TLS on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :tls
			expect( LDAP::SSLConn ).to receive( :new ).with( TEST_HOST, TEST_PORT, true ).
				and_return( @conn )
			expect( @dir.conn ).to eq( @conn )
		end

		it "connects over SSL on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :ssl
			expect( LDAP::SSLConn ).to receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( @conn )
			expect( @dir.conn ).to eq( @conn )
		end
	end

	describe "instances with a connection" do

		before( :each ) do
			@dir = Treequel.directory( TEST_LDAPURI )
			@dir.instance_variable_set( :@conn, @conn )
		end

		it "can bind with the given user DN and password" do
			expect( @conn ).to receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@dir.bind( TEST_BIND_DN, TEST_BIND_PASS )
		end

		it "can bind with the DN of the given Branch (or a quack-alike) and password" do
			branch = double( "branch", :dn => TEST_BIND_DN )
			expect( @conn ).to receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@dir.bind( branch, TEST_BIND_PASS )
		end

		it "can temporarily bind as another user for the duration of a block" do
			dupconn = double( "duplicate connection" )
			expect( @conn ).to receive( :dup ).and_return( dupconn )
			expect( dupconn ).to receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			expect( @conn ).to_not receive( :bind )

			@dir.bound_as( TEST_BIND_DN, TEST_BIND_PASS ) do
				expect( @dir.conn ).to eq( dupconn )
			end

			expect( @dir.conn ).to eq( @conn )
		end

		it "knows if its underlying connection is already bound" do
			expect( @conn ).to receive( :bound? ).and_return( false, true )
			expect( @dir ).to_not be_bound()
			expect( @dir ).to be_bound()
		end

		it "can be unbound, which replaces the bound connection with a duplicate that is unbound" do
			dupconn = double( "duplicate connection" )
			expect( @conn ).to receive( :bound? ).and_return( true )
			expect( @conn ).to receive( :dup ).and_return( dupconn )
			expect( @conn ).to receive( :unbind )

			@dir.unbind

			expect( @dir.conn ).to eq( dupconn )
		end

		it "doesn't do anything if told to unbind but the current connection is not bound" do
			expect( @conn ).to receive( :bound? ).and_return( false )
			expect( @conn ).to_not receive( :dup )
			expect( @conn ).to_not receive( :unbind )

			@dir.unbind

			expect( @dir.conn ).to eq( @conn )
		end

		it "can look up a Branch's corresponding LDAP::Entry hash" do
			branch = double( "branch" )

			expect( branch ).to receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )

			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_PERSON_DN, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)' ).
				and_return([ :the_entry ])

			expect( @dir.get_entry( branch ) ).to eq( :the_entry )
		end

		it "can look up a Branch's corresponding LDAP::Entry hash with operational attributes included" do
			branch = double( "branch" )

			expect( branch ).to receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )

			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_PERSON_DN, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)', ['*', '+'] ).
				and_return([ :the_extended_entry ])

			expect( @dir.get_extended_entry( branch ) ).to eq( :the_extended_entry )
		end

		it "can search for entries and return them as Sequel::Branch objects" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'
			branch = double( "branch" )

			found_branch1 = instance_double( Treequel::Branch, "entry1 branch" )
			found_branch2 = instance_double( Treequel::Branch, "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			expect( @conn ).to receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )

			expect( @dir.search( base, :base, filter ) ).to eq( [ found_branch1, found_branch2 ] )
		end


		it "can search for entries and yield them as Sequel::Branch objects" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'
			branch = double( "branch", :dn => "thedn" )

			found_branch1 = instance_double( Treequel::Branch, "entry1 branch" )
			found_branch2 = instance_double( Treequel::Branch, "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			expect( @conn ).to receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )

			results = []
			@dir.search( base, :base, filter ) do |branch|
				results << branch
			end

			expect( results ).to eq( [ found_branch1, found_branch2 ] )
		end


		it "returns branches with operational attributes enabled if the base is a branch with " +
		   "operational attributes enabled" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'

			branch = double( "branch", :dn => TEST_PEOPLE_DN )
			expect( branch ).to receive( :respond_to? ).with( :include_operational_attrs? ).
				at_least( :once ).
				and_return( true )
			expect( branch ).to receive( :respond_to? ).with( :dn ).
				and_return( true )
			expect( branch ).to receive( :include_operational_attrs? ).at_least( :once ).
				and_return( true )

			found_branch1 = instance_double( Treequel::Branch, "entry1 branch" )
			found_branch2 = instance_double( Treequel::Branch, "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			expect( @conn ).to receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			expect( found_branch1 ).to receive( :include_operational_attrs= ).with( true )
			expect( Treequel::Branch ).to receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )
			expect( found_branch2 ).to receive( :include_operational_attrs= ).with( true )

			results = []
			@dir.search( branch, :base, filter ) do |branch|
				results << branch
			end

			expect( results ).to eq( [ found_branch1, found_branch2 ] )
		end


		it "catches plain RuntimeErrors raised by #search2 and re-casts them as " +
		   "more-interesting errors" do
			expect( @conn ).to receive( :search_ext2 ).
				and_raise( RuntimeError.new('no result returned by search') )
			expect( @conn ).to receive( :err ).and_return( -1 )

			expect {
				@dir.search( TEST_BASE_DN, :base, '(objectClass=*)' )
			}.to raise_error( LDAP::ResultError, /can't contact/i )
		end


		it "knows if a connection has been established" do
			expect( @dir ).to be_connected()
			@dir.instance_variable_set( :@conn, nil )
			expect( @dir ).to_not be_connected()
		end

		it "can reconnect if its underlying connection goes away" do
			expect( @conn ).to receive( :search_ext2 ).and_raise( LDAP::ResultError.new("Can't contact LDAP server") )

			second_conn = double( "LDAP connection", :set_option => true, :bound? => false )
			expect( LDAP::SSLConn ).to receive( :new ).and_return( second_conn )
			expect( second_conn ).to receive( :search_ext2 ).and_return([])

			already_tried_reconnect = false
			begin
				@dir.search( TEST_PEOPLE_DN, :base, '(objectClass=*)' )
			rescue
				unless already_tried_reconnect
					already_tried_reconnect = true
					@dir.reconnect and retry
				end
			end
		end

		it "re-raises an exception rescued during a reconnect as a RuntimeError" do
			expect( LDAP::SSLConn ).to receive( :new ).
				and_raise( LDAP::ResultError.new("Can't contact LDAP server") )

			expect {
				@dir.reconnect
			}.to raise_exception( RuntimeError, /couldn't reconnect/i )
		end


		it "doesn't retain its connection when duplicated" do
			expect( LDAP::SSLConn ).to receive( :new ) do
				double( "LDAP connection", :set_option => true, :bound? => false )
			end

			expect( @dir.dup.conn ).to_not equal( @dir.conn )
		end

		describe "and a custom search results class" do

			before( :each ) do
				@customclass = Class.new {
					def self::new_from_entry( entry, directory )
						new( entry, directory, 'a_dn' )
					end
					def initialize( entry, directory, dn )
						@entry = entry
						@directory = directory
						@dn = dn
					end
					attr_reader :entry, :directory, :dn
				}

			end

			it "can search for entries and return them as instances of a custom class" do
				filter = '(|(uid=jonlong)(uid=margento))'
				base = double( "branch" )

				found_branch1 = instance_double( Treequel::Branch, "entry1 branch" )
				found_branch2 = instance_double( Treequel::Branch, "entry2 branch" )

				# Do the search
				entries = [
					{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
					{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
				]
				expect( @conn ).to receive( :search_ext2 ).
					with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'],
					      false, nil, nil, 0, 0, 0, '', nil ).
					and_return( entries )

				rval = @dir.search( base, :base, filter, :results_class => @customclass )

				expect( rval[0] ).to be_an_instance_of( @customclass )
				expect( rval[0].entry ).to eq( entries[0] )
				expect( rval[0].directory ).to eq( @dir )
				expect( rval[1] ).to be_an_instance_of( @customclass )
				expect( rval[1].entry ).to eq( entries[1] )
				expect( rval[1].directory ).to eq( @dir )
			end


			it "returns instances of the base argument if it responds to new_from_entry and no " +
			   "custom class is specified" do

				base = @customclass.new( nil, nil, TEST_PEOPLE_DN )
				filter = '(|(uid=jonlong)(uid=margento))'
				branch = double( "branch" )

				found_branch1 = instance_double( Treequel::Branch, "entry1 branch" )
				found_branch2 = instance_double( Treequel::Branch, "entry2 branch" )

				# Do the search
				entries = [
					{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
					{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
				]
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_PEOPLE_DN, LDAP::LDAP_SCOPE_BASE, filter, ['*'],
					      false, nil, nil, 0, 0, 0, '', nil ).
					and_return( entries )

				rval = @dir.search( base, :base, filter )

				expect( rval[0] ).to be_an_instance_of( @customclass )
				expect( rval[0].entry ).to eq( entries[0] )
				expect( rval[0].directory ).to eq( @dir )
				expect( rval[1] ).to be_an_instance_of( @customclass )
				expect( rval[1].entry ).to eq( entries[1] )
				expect( rval[1].directory ).to eq( @dir )
			end

		end

		it "can turn a DN string into an RDN string from its base" do
			expect( @dir.rdn_to( TEST_PERSON_DN ) ).to eq( TEST_PERSON_DN.sub( /,#{TEST_BASE_DN}$/, '' ) )
		end

		it "can fetch the server's schema" do
			expect( @dir.schema ).to be_a( Treequel::Schema )
		end

		it "creates branches for messages that match valid attributeType OIDs" do
			rval = @dir.ou( :people )
			expect( rval.dn.downcase ).to eq( TEST_PEOPLE_DN.downcase )
		end

		it "doesn't create branches for messages that don't match valid attributeType OIDs" do
			expect { @dir.void('sbc') }.to raise_error( NoMethodError )
		end

		it "can modify the record corresponding to a Branch in the directory" do
			branch = double( "branch" )
			expect( branch ).to receive( :dn ).at_least( :once ).and_return( :the_branches_dn )

			expect( @conn ).to receive( :modify ).with( :the_branches_dn, 'cn' => ['nomblywob'] )

			@dir.modify( branch, 'cn' => ['nomblywob'] )
		end

		it "can modify the record corresponding to a Branch in the directory via LDAP::Mods" do
			branch = double( "branch" )
			expect( branch ).to receive( :dn ).at_least( :once ).and_return( :the_branches_dn )
			delmod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', ['georgina boots'] )

			expect( @conn ).to receive( :modify ).with( :the_branches_dn, [delmod] )

			@dir.modify( branch, [delmod] )
		end

		it "can delete the record corresponding to a Branch from the directory" do
			branch = double( "branch" )
			expect( branch ).to receive( :dn ).at_least( :once ).and_return( :the_branches_dn )

			expect( @conn ).to receive( :delete ).once.with( :the_branches_dn )

			@dir.delete( branch )
		end

		it "can create an entry for a Branch" do
			newattrs = {
				:cn => 'Chilly T',
				:desc => 'Audi like Jetta',
				:objectClass => :room,
			}

			branch = Treequel::Branch.new( @directory, TEST_PERSON_DN, newattrs )

			expect( @conn ).to receive( :add ).with( TEST_PERSON_DN, {
				'cn' => ['Chilly T'],
				'desc' => ['Audi like Jetta'],
				'objectClass' => ['room'],
			})

			@dir.create( branch, newattrs )
		end


		it "can create an entry with a DN and LDAP::Mod objects instead of an attribute hash" do
			mods = [
				ldap_mod_add( :cn, 'Chilly T' ),
				ldap_mod_add( :desc, 'Audi like Jetta' ),
				ldap_mod_add( :objectClass, 'room' ),
			]

			expect( @conn ).to receive( :add ).with( TEST_PERSON_DN, mods )

			@dir.create( TEST_PERSON_DN, mods )
		end

		it "can move a record to a new dn within the same branch" do
			# expect( @dir ).to receive( :bound? ).and_return( false )
			branch = double( "sibling branch obj" )
			expect( branch ).to receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )
			expect( branch ).to receive( :split_dn ).at_least( :once ).
				and_return([ TEST_PERSON_RDN, TEST_PEOPLE_DN ])

			expect( @conn ).to receive( :modrdn ).with( TEST_PERSON_DN, TEST_PERSON2_RDN, true )
			expect( branch ).to receive( :dn= ).with( TEST_PERSON2_DN )

			@dir.move( branch, TEST_PERSON2_DN )
		end


		### Datatype conversion

		it "allows an attribute conversion to be overridden by a block for a valid syntax OID" do
			@dir.add_attribute_conversion( OIDS::BIT_STRING_SYNTAX ) do |unconverted_value, directory|
				unconverted_value.to_sym
			end
			expect( @dir.convert_to_object( OIDS::BIT_STRING_SYNTAX, 'a_value' ) ).to eq( :a_value )
		end

		it "allows an attribute conversion to be overridden by a Hash for a valid syntax OID" do
			@dir.add_attribute_conversion( OIDS::BOOLEAN_SYNTAX, {'true' => true, 'false' => false} )
			expect( @dir.convert_to_object( OIDS::BOOLEAN_SYNTAX, 'true' ) ).to eq( true )
		end

		it "allows an attribute conversion to be cleared by adding a nil mapping" do
			@dir.add_attribute_conversion( OIDS::BOOLEAN_SYNTAX, {'true' => true, 'false' => false} )
			@dir.add_attribute_conversion( OIDS::BOOLEAN_SYNTAX )
			expect( @dir.convert_to_object( OIDS::BOOLEAN_SYNTAX, 'true' ) ).to eq( 'true' )
		end

		it "allows an object conversion to be overridden by a block for a valid syntax OID" do
			@dir.add_object_conversion( OIDS::BIT_STRING_SYNTAX ) do |unconverted_value, directory|
				unconverted_value.to_s
			end
			expect( @dir.convert_to_attribute( OIDS::BIT_STRING_SYNTAX, :a_value ) ).to eq( 'a_value' )
		end

		it "allows an object conversion to be overridden by a Hash for a valid syntax OID" do
			@dir.add_object_conversion( OIDS::BOOLEAN_SYNTAX, {false => 'FALSE', true => 'TRUE'} )
			expect( @dir.convert_to_attribute( OIDS::BOOLEAN_SYNTAX, false ) ).to eq( 'FALSE' )
		end

		it "allows an object conversion to be cleared by adding a nil mapping" do
			@dir.add_object_conversion( OIDS::BOOLEAN_SYNTAX, {'true' => true, 'false' => false} )
			@dir.add_object_conversion( OIDS::BOOLEAN_SYNTAX )
			expect( @dir.convert_to_attribute( OIDS::BOOLEAN_SYNTAX, true ) ).to eq( 'true' )
		end

		it "forces the encoding of DirectoryString attributes to UTF-8", :ruby_19 do
			directory_value = 'a value'.force_encoding( Encoding::ASCII_8BIT )
			rval = @dir.convert_to_object( OIDS::STRING_SYNTAX, directory_value )
			expect( rval.encoding ).to eq( Encoding::UTF_8 )
		end

		### Controls support
		describe "to a server that supports controls introspection" do
			before( :each ) do
				@control = Module.new { include Treequel::Control }
				expect( @conn ).to receive( :search_ext2 ).
					with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
					and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported controls as OIDs" do
				expect( @dir.supported_control_oids ).to eq( TEST_DSE.first['supportedControl'] )
			end

			it "allows one to fetch the list of supported controls as control names" do
				expected_control_names = TEST_DSE.first['supportedControl'].
					collect {|oid| Treequel::Constants::CONTROL_NAMES[oid] }

				expect( @dir.supported_controls ).to eq( expected_control_names )
			end

			it "allows the registration of one or more Treequel::Control modules" do
				@control.const_set( :OID, TEST_DSE.first['supportedControl'].first )
				@dir.register_controls( @control )
				expect( @dir.registered_controls ).to eq( [ @control ] )
			end

			it "raises an exception if the directory doesn't support registered controls" do
				@control.const_set( :OID, '8.6.7.5.309' )
				expect {
					@dir.register_controls( @control )
				}.to raise_error( Treequel::UnsupportedControl, /not supported/i )

				expect( @dir.registered_controls ).to eq( [] )
			end

			it "raises an exception if a registered control doesn't define an OID" do
				@control.const_set( :OID, nil )
				expect {
					@dir.register_controls( @control )
				}.to raise_error( NotImplementedError, /doesn't define/i )
			end
		end


		describe "to a server that supports extensions introspection" do
			before( :each ) do
				expect( @conn ).to receive( :search_ext2 ).
					with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
					and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported extensions as OIDs" do
				expect( @dir.supported_extension_oids ).to eq( TEST_DSE.first['supportedExtension'] )
			end

			it "allows one to fetch the list of supported extensions as extension names" do
				expected_extension_names = TEST_DSE.first['supportedExtension'].
					collect {|oid| Treequel::Constants::EXTENSION_NAMES[oid] }
				expect( @dir.supported_extensions ).to eq( expected_extension_names )
			end

		end


		describe "to a server that supports features introspection" do
			before( :each ) do
				expect( @conn ).to receive( :search_ext2 ).
					with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
					and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported features as OIDs" do
				expect( @dir.supported_feature_oids ).to eq( TEST_DSE.first['supportedFeatures'] )
			end

			it "allows one to fetch the list of supported features as feature names" do
				expected_feature_names = TEST_DSE.first['supportedFeatures'].
					collect {|oid| Treequel::Constants::FEATURE_NAMES[oid] }
				expect( @dir.supported_features ).to eq( expected_feature_names )
			end

		end

		describe "to a server that doesn't support features introspection" do
			before( :each ) do
				expect( @conn ).to receive( :search_ext2 ).
					with( "", 0, "(objectClass=*)", ["+", '*'], false, nil, nil, 0, 0, 0, "", nil ).
					and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported features as OIDs" do
				expect( @dir.supported_feature_oids ).to eq( TEST_DSE.first['supportedFeatures'] )
			end

			it "allows one to fetch the list of supported features as feature names" do
				expected_feature_names = TEST_DSE.first['supportedFeatures'].
					collect {|oid| Treequel::Constants::FEATURE_NAMES[oid] }
				expect( @dir.supported_features ).to eq( expected_feature_names )
			end

		end

	end
end


# vim: set nosta noet ts=4 sw=4:

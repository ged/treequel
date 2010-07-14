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

require 'treequel/directory'
require 'treequel/branch'
require 'treequel/control'


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Directory do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	before( :each ) do
		@options = {
			:host         => TEST_HOST,
			:port         => TEST_PORT,
			:base_dn      => TEST_BASE_DN,
			:connect_type => :plain,
		}
		@conn = mock( "LDAP connection", :set_option => true, :bound? => false )
		LDAP::SSLConn.stub!( :new ).and_return( @conn )
		@conn.stub!( :root_dse ).and_return( nil )
	end


	it "is created with reasonable default options if none are specified" do
		dir = Treequel::Directory.new

		dir.host.should == 'localhost'
		dir.port.should == 389
		dir.connect_type.should == :tls
		dir.base_dn.should == ''
	end

	it "is created with the specified options if options are specified" do
		dir = Treequel::Directory.new( @options )

		dir.host.should == TEST_HOST
		dir.port.should == TEST_PORT
		dir.connect_type.should == @options[:connect_type]
		dir.base_dn.should == TEST_BASE_DN
	end

	it "binds immediately if user/pass is included in the ldap URI" do
		conn = mock( "LDAP connection", :set_option => true )

		LDAP::Conn.should_receive( :new ).with( TEST_HOST, TEST_PORT ).
			and_return( conn )
		conn.should_receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )

		dir = Treequel::Directory.new( @options.merge(:bind_dn => TEST_BIND_DN, :pass => TEST_BIND_PASS) )
		dir.bound_user.should == TEST_BIND_DN
	end

	it "uses the first namingContext from the Root DSE if no base is specified" do
		conn = mock( "LDAP connection", :set_option => true )
		LDAP::Conn.stub!( :new ).and_return( conn )
		conn.should_receive( :root_dse ).and_return( TEST_DSE )

		@dir = Treequel::Directory.new( @options.merge(:base_dn => nil) )
		@dir.base_dn.should == TEST_BASE_DN
	end

	it "can return its root element as a Branch instance" do
		@dir = Treequel::Directory.new( @options )
		@dir.base.should be_a( Treequel::Branch )
		@dir.base.dn.should == TEST_BASE_DN
	end

	it "can return its root element as an instance of its results class if it's been set" do
		subtype = Class.new( Treequel::Branch )
		@dir = Treequel::Directory.new( @options )

		@dir.results_class = subtype

		@dir.base.should be_a( subtype )
		@dir.base.dn.should == TEST_BASE_DN
	end


	describe "instances without existing connections" do

		before( :each ) do
			@dir = Treequel::Directory.new( @options )
			@conn = mock( "ldap connection", :set_option => true )
		end


		it "stringifies as a description which includes the host, port, connection type and base" do
			@dir.to_s.should =~ /#{Regexp.quote(TEST_HOST)}/
			@dir.to_s.should =~ /#{TEST_PORT}/
			@dir.to_s.should =~ /\b#{@dir.connect_type}\b/
			@dir.to_s.should =~ /#{TEST_BASE_DN}/i
		end

		it "connects on demand to the configured directory server" do
			LDAP::Conn.should_receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( @conn )
			@dir.conn.should == @conn
		end

		it "connects with TLS on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :tls
			LDAP::SSLConn.should_receive( :new ).with( TEST_HOST, TEST_PORT, true ).
				and_return( @conn )
			@dir.conn.should == @conn
		end

		it "connects over SSL on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :ssl
			LDAP::SSLConn.should_receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( @conn )
			@dir.conn.should == @conn
		end
	end

	describe "instances with a connection" do

		before( :each ) do
			@conn = mock( "ldap connection", :bound? => false )

			@dir = Treequel::Directory.new( @options )
			@dir.instance_variable_set( :@conn, @conn )

			@schema = mock( "Directory schema" )
			@conn.stub!( :schema ).and_return( :the_schema )
			Treequel::Schema.stub!( :new ).with( :the_schema ).and_return( @schema )
			@schema.stub!( :attribute_types ).and_return({ :cn => :a_value, :ou => :a_value })
		end

		it "can bind with the given user DN and password" do
			@conn.should_receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@dir.bind( TEST_BIND_DN, TEST_BIND_PASS )
		end

		it "can bind with the DN of the given Branch (or a quack-alike) and password" do
			branch = stub( "branch", :dn => TEST_BIND_DN )
			@conn.should_receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@dir.bind( branch, TEST_BIND_PASS )
		end

		it "can temporarily bind as another user for the duration of a block" do
			dupconn = mock( "duplicate connection" )
			@conn.should_receive( :dup ).and_return( dupconn )
			dupconn.should_receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@conn.should_not_receive( :bind )

			@dir.bound_as( TEST_BIND_DN, TEST_BIND_PASS ) do
				@dir.conn.should == dupconn
			end

			@dir.conn.should == @conn
		end

		it "knows if its underlying connection is already bound" do
			@conn.should_receive( :bound? ).and_return( false, true )
			@dir.should_not be_bound()
			@dir.should be_bound()
		end


		it "can be unbound, which replaces the bound connection with a duplicate that is unbound" do
			dupconn = mock( "duplicate connection" )
			@conn.should_receive( :bound? ).and_return( true )
			@conn.should_receive( :dup ).and_return( dupconn )
			@conn.should_receive( :unbind )

			@dir.unbind

			@dir.conn.should == dupconn
		end


		it "doesn't do anything if told to unbind but the current connection is not bound" do
			@conn.should_receive( :bound? ).and_return( false )
			@conn.should_not_receive( :dup )
			@conn.should_not_receive( :unbind )

			@dir.unbind

			@dir.conn.should == @conn
		end

		it "can look up a Branch's corresponding LDAP::Entry hash" do
			branch = mock( "branch" )

			branch.should_receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )

			@conn.should_receive( :search_ext2 ).
				with( TEST_PERSON_DN, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)' ).
				and_return([ :the_entry ])

			@dir.get_entry( branch ).should == :the_entry
		end

		it "can look up a Branch's corresponding LDAP::Entry hash with operational attributes included" do
			branch = mock( "branch" )

			branch.should_receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )

			@conn.should_receive( :search_ext2 ).
				with( TEST_PERSON_DN, LDAP::LDAP_SCOPE_BASE, '(objectClass=*)', ['*', '+'] ).
				and_return([ :the_extended_entry ])

			@dir.get_extended_entry( branch ).should == :the_extended_entry
		end

		it "can search for entries and return them as Sequel::Branch objects" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'
			branch = mock( "branch" )

			found_branch1 = stub( "entry1 branch" )
			found_branch2 = stub( "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			@conn.should_receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )

			@dir.search( base, :base, filter ).should == [ found_branch1, found_branch2 ]
		end


		it "can search for entries and yield them as Sequel::Branch objects" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'
			branch = mock( "branch", :dn => "thedn" )

			found_branch1 = stub( "entry1 branch" )
			found_branch2 = stub( "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			@conn.should_receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )

			results = []
			@dir.search( base, :base, filter ) do |branch|
				results << branch
			end

			results.should == [ found_branch1, found_branch2 ]
		end


		it "returns branches with operational attributes enabled if the base is a branch with " +
		   "operational attributes enabled" do
			base = TEST_PEOPLE_DN
			filter = '(|(uid=jonlong)(uid=margento))'

			branch = mock( "branch", :dn => TEST_PEOPLE_DN )
			branch.should_receive( :respond_to? ).with( :include_operational_attrs? ).
				at_least( :once ).
				and_return( true )
			branch.should_receive( :respond_to? ).with( :dn ).
				and_return( true )
		   	branch.stub!( :include_operational_attrs? ).and_return( true )

			found_branch1 = stub( "entry1 branch" )
			found_branch2 = stub( "entry2 branch" )

			# Do the search
			entries = [
				{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
				{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
			]
			@conn.should_receive( :search_ext2 ).
				with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'], false, nil, nil, 0, 0, 0, '', nil ).
				and_return( entries )

			# Turn found entries into Branch objects
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			found_branch1.should_receive( :include_operational_attrs= ).with( true )
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )
			found_branch2.should_receive( :include_operational_attrs= ).with( true )

			results = []
			@dir.search( branch, :base, filter ) do |branch|
				results << branch
			end

			results.should == [ found_branch1, found_branch2 ]
		end


		it "catches plain RuntimeErrors raised by #search2 and re-casts them as " +
		   "more-interesting errors" do
			@conn.should_receive( :search_ext2 ).
				and_raise( RuntimeError.new('no result returned by search') )
			@conn.should_receive( :err ).and_return( -1 )

			expect {
				@dir.search( TEST_BASE_DN, :base, '(objectClass=*)' )
			}.to raise_error( LDAP::ResultError, /can't contact/i )
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
				base = mock( "branch" )

				found_branch1 = stub( "entry1 branch" )
				found_branch2 = stub( "entry2 branch" )

				# Do the search
				entries = [
					{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
					{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
				]
				@conn.should_receive( :search_ext2 ).
					with( base, LDAP::LDAP_SCOPE_BASE, filter, ['*'],
					      false, nil, nil, 0, 0, 0, '', nil ).
					and_return( entries )

				rval = @dir.search( base, :base, filter, :results_class => @customclass )

				rval[0].should be_an_instance_of( @customclass )
				rval[0].entry.should == entries[0]
				rval[0].directory.should == @dir
				rval[1].should be_an_instance_of( @customclass )
				rval[1].entry.should == entries[1]
				rval[1].directory.should == @dir
			end


			it "returns instances of the base argument if it responds to new_from_entry and no " +
			   "custom class is specified" do

				base = @customclass.new( nil, nil, TEST_PEOPLE_DN )
				filter = '(|(uid=jonlong)(uid=margento))'
				branch = mock( "branch" )

				found_branch1 = stub( "entry1 branch" )
				found_branch2 = stub( "entry2 branch" )

				# Do the search
				entries = [
					{ 'dn' => ["uid=jonlong,#{TEST_PEOPLE_DN}"] },
					{ 'dn' => ["uid=margento,#{TEST_PEOPLE_DN}"] },
				]
				@conn.should_receive( :search_ext2 ).
					with( TEST_PEOPLE_DN, LDAP::LDAP_SCOPE_BASE, filter, ['*'],
					      false, nil, nil, 0, 0, 0, '', nil ).
					and_return( entries )

				rval = @dir.search( base, :base, filter )

				rval[0].should be_an_instance_of( @customclass )
				rval[0].entry.should == entries[0]
				rval[0].directory.should == @dir
				rval[1].should be_an_instance_of( @customclass )
				rval[1].entry.should == entries[1]
				rval[1].directory.should == @dir
			end

		end

		it "can turn a DN string into an RDN string from its base" do
			@dir.rdn_to( TEST_PERSON_DN ).should == TEST_PERSON_DN.sub( /,#{TEST_BASE_DN}$/, '' )
		end

		it "can fetch the server's schema" do
			@conn.should_receive( :schema ).and_return( :the_schema )
			Treequel::Schema.should_receive( :new ).with( :the_schema ).
				and_return( :the_parsed_schema )
			@dir.schema.should == :the_parsed_schema
		end

		it "creates branches for messages that match valid attributeType OIDs" do
			@schema.should_receive( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value })

			@dir.stub!( :bound? ).and_return( false )
			rval = @dir.ou( :people )
			rval.dn.downcase.should == TEST_PEOPLE_DN.downcase
		end

		it "doesn't create branches for messages that don't match valid attributeType OIDs" do
			@schema.should_receive( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value })

			expect { @dir.void('sbc') }.to raise_error( NoMethodError )
		end

		it "can modify the record corresponding to a Branch in the directory" do
			branch = mock( "branch" )
			branch.should_receive( :dn ).at_least( :once ).and_return( :the_branches_dn )

			@conn.should_receive( :modify ).with( :the_branches_dn, 'cn' => ['nomblywob'] )

			@dir.modify( branch, 'cn' => ['nomblywob'] )
		end

		it "can modify the record corresponding to a Branch in the directory via LDAP::Mods" do
			branch = mock( "branch" )
			branch.should_receive( :dn ).at_least( :once ).and_return( :the_branches_dn )
			delmod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', ['georgina boots'] )

			@conn.should_receive( :modify ).with( :the_branches_dn, [delmod] )

			@dir.modify( branch, [delmod] )
		end

		it "can delete the record corresponding to a Branch from the directory" do
			branch = mock( "branch" )
			branch.should_receive( :dn ).at_least( :once ).and_return( :the_branches_dn )

			@conn.should_receive( :delete ).once.with( :the_branches_dn )

			@dir.delete( branch )
		end

		it "can create an entry for a Branch" do
			newattrs = {
				:cn => 'Chilly T',
				:desc => 'Audi like Jetta',
				:objectClass => :room,
			}
			rdn_attrs = {
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE]
			}
			addattrs = {
				'cn' => ['Chilly T'],
				'desc' => ['Audi like Jetta'],
				'objectClass' => ['room'],
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE],
			}

			branch = mock( "new person branch" )
			branch.should_receive( :dn ).and_return( TEST_PERSON_DN )
			branch.should_receive( :rdn_attributes ).at_least( :once ).and_return( rdn_attrs )

			room_objectclass = stub( 'room objectClass', :structural? => true )
			@schema.should_receive( :object_classes ).at_least( :once ).and_return({ 
				:room => room_objectclass,
			})

			@conn.should_receive( :add ).with( TEST_PERSON_DN, addattrs )

			@dir.create( branch, newattrs )
		end


		it "doesn't include duplicates when smushing RDN attributes" do
			newattrs = {
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE],
				:cn => 'Chilly T',
				:desc => 'Audi like Jetta',
				:objectClass => :room,
			}
			rdn_attrs = {
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE]
			}
			addattrs = {
				'cn' => ['Chilly T'],
				'desc' => ['Audi like Jetta'],
				'objectClass' => ['room'],
				TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE],
			}

			branch = mock( "new person branch" )
			branch.should_receive( :dn ).and_return( TEST_PERSON_DN )
			branch.should_receive( :rdn_attributes ).at_least( :once ).and_return( rdn_attrs )

			room_objectclass = stub( 'room objectClass', :structural? => true )
			@schema.should_receive( :object_classes ).at_least( :once ).and_return({ 
				:room => room_objectclass,
			})

			@conn.should_receive( :add ).with( TEST_PERSON_DN, addattrs )

			@dir.create( branch, newattrs )
		end


		it "can move a record to a new dn within the same branch" do
			@dir.stub!( :bound? ).and_return( false )
			branch = mock( "sibling branch obj" )
			branch.should_receive( :dn ).at_least( :once ).and_return( TEST_PERSON_DN )
			branch.should_receive( :split_dn ).at_least( :once ).
				and_return([ TEST_PERSON_RDN, TEST_PEOPLE_DN ])

			@conn.should_receive( :modrdn ).with( TEST_PERSON_DN, TEST_PERSON2_RDN, true )
			branch.should_receive( :dn= ).with( TEST_PERSON2_DN )

			@dir.move( branch, TEST_PERSON2_DN )
		end


		### Datatype conversion

		it "allows a mapping to be overridden by a block for a valid syntax OID" do
			@dir.add_syntax_mapping( OIDS::BIT_STRING_SYNTAX ) do |unconverted_value, directory|
				unconverted_value.to_sym
			end
			@dir.convert_syntax_value( OIDS::BIT_STRING_SYNTAX, 'a_value' ).should == :a_value
		end

		it "allows a mapping to be overridden by a block with only one parameter for a " +
		   "valid syntax OID (backwards-compatibility)" do
			pending "doesn't work under 1.8" if RUBY_VERSION < '1.9.1'
			@dir.add_syntax_mapping( OIDS::BIT_STRING_SYNTAX ) do |unconverted_value|
				unconverted_value.to_sym
			end
			@dir.convert_syntax_value( OIDS::BIT_STRING_SYNTAX, 'a_value' ).should == :a_value
		end

		it "allows a mapping to be overridden by a Hash for a valid syntax OID" do
			@dir.add_syntax_mapping( OIDS::BOOLEAN_SYNTAX, {'true' => true, 'false' => false} )
			@dir.convert_syntax_value( OIDS::BOOLEAN_SYNTAX, 'true' ).should == true
		end

		it "allows a mapping to be cleared by adding a nil mapping" do
			@dir.add_syntax_mapping( OIDS::BOOLEAN_SYNTAX, {'true' => true, 'false' => false} )
			@dir.add_syntax_mapping( OIDS::BOOLEAN_SYNTAX )
			@dir.convert_syntax_value( OIDS::BOOLEAN_SYNTAX, 'true' ).should == 'true'
		end


		### Controls support
		describe "to a server that supports controls introspection" do
			before( :each ) do
				@control = Module.new { include Treequel::Control }
				@conn.should_receive( :root_dse ).and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported controls as OIDs" do
				@dir.supported_control_oids.should == TEST_DSE.first['supportedControl']
			end

			it "allows one to fetch the list of supported controls as control names" do
				@dir.supported_controls.should == TEST_DSE.first['supportedControl'].
					collect {|oid| Treequel::Constants::CONTROL_NAMES[oid] }
			end

			it "allows the registration of one or more Treequel::Control modules" do
				@control.const_set( :OID, TEST_DSE.first['supportedControl'].first )
				@dir.register_controls( @control )
				@dir.registered_controls.should == [ @control ]
			end

			it "raises an exception if the directory doesn't support registered controls" do
				@control.const_set( :OID, '8.6.7.5.309' )
				expect {
					@dir.register_controls( @control )
				}.to raise_error( Treequel::UnsupportedControl, /not supported/i )

				@dir.registered_controls.should == []
			end

			it "raises an exception if a registered control doesn't define an OID" do
				expect {
					@dir.register_controls( @control )
				}.to raise_error( NotImplementedError, /doesn't define/i )
			end
		end


		describe "to a server that supports extensions introspection" do
			before( :each ) do
				@conn.should_receive( :root_dse ).and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported extensions as OIDs" do
				@dir.supported_extension_oids.should == TEST_DSE.first['supportedExtension']
			end

			it "allows one to fetch the list of supported extensions as extension names" do
				@dir.supported_extensions.should == TEST_DSE.first['supportedExtension'].
					collect {|oid| Treequel::Constants::EXTENSION_NAMES[oid] }
			end

		end


		describe "to a server that supports features introspection" do
			before( :each ) do
				@conn.should_receive( :root_dse ).and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported features as OIDs" do
				@dir.supported_feature_oids.should == TEST_DSE.first['supportedFeatures']
			end

			it "allows one to fetch the list of supported features as feature names" do
				@dir.supported_features.should == TEST_DSE.first['supportedFeatures'].
					collect {|oid| Treequel::Constants::FEATURE_NAMES[oid] }
			end

		end

		describe "to a server that doesn't support features introspection" do
			before( :each ) do
				@conn.should_receive( :root_dse ).and_return( TEST_DSE )
			end


			it "allows one to fetch the list of supported features as OIDs" do
				@dir.supported_feature_oids.should == TEST_DSE.first['supportedFeatures']
			end

			it "allows one to fetch the list of supported features as feature names" do
				@dir.supported_features.should == TEST_DSE.first['supportedFeatures'].
					collect {|oid| Treequel::Constants::FEATURE_NAMES[oid] }
			end

		end

	end
end


# vim: set nosta noet ts=4 sw=4:

#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel/directory'
	require 'treequel/branch'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


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
			:base         => TEST_BASE_DN,
			:connect_type => :plain,
		}
	end
	

	it "is created with reasonable default options if none are specified" do
		dir = Treequel::Directory.new

		dir.host.should == 'localhost'
		dir.port.should == 389
		dir.connect_type.should == :tls
		dir.base.should == ''
	end

	it "is created with the specified options if options are specified" do
		dir = Treequel::Directory.new( @options )
		
		dir.host.should == TEST_HOST
		dir.port.should == TEST_PORT
		dir.connect_type.should == @options[:connect_type]
		dir.base.should == TEST_BASE_DN
	end


	describe "instances without existing connections" do
		
		before( :each ) do
			@dir = Treequel::Directory.new( @options )
		end


		it "stringifies as a description which includes the host, port, connection type and base" do
			@dir.to_s.should =~ /#{Regexp.quote(TEST_HOST)}/
			@dir.to_s.should =~ /#{TEST_PORT}/
			@dir.to_s.should =~ /\b#{@dir.connect_type}\b/
			@dir.to_s.should =~ /#{TEST_BASE_DN}/i
		end
		
		it "connects on demand to the configured directory server" do
			LDAP::Conn.should_receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( :ldap_conn )
			@dir.conn.should == :ldap_conn
		end
		
		it "connects with TLS on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :tls
			LDAP::SSLConn.should_receive( :new ).with( TEST_HOST, TEST_PORT, true ).
				and_return( :ldap_conn )
			@dir.conn.should == :ldap_conn
		end
		
		it "connects over SSL on demand to the configured directory server if configured to do so" do
			@dir.connect_type = :ssl
			LDAP::SSLConn.should_receive( :new ).with( TEST_HOST, TEST_PORT ).
				and_return( :ldap_conn )
			@dir.conn.should == :ldap_conn
		end
	end

	describe "instances with a connection" do
		
		before( :each ) do
			@conn = mock( "ldap connection" )
			@dir = Treequel::Directory.new( @options )
			@dir.instance_variable_set( :@conn, @conn )
		end


		it "can bind with the given user DN and password" do
			@conn.should_receive( :bind ).with( TEST_BIND_DN, TEST_BIND_PASS )
			@dir.bind( TEST_BIND_DN, TEST_BIND_PASS )
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
			
			branch.should_receive( :base ).and_return( TEST_PEOPLE_DN )
			branch.should_receive( :attr_pair ).and_return( TEST_PERSON_DN_PAIR )
			
			@conn.should_receive( :search2 ).
				with( TEST_PEOPLE_DN, LDAP::LDAP_SCOPE_ONELEVEL, TEST_PERSON_DN_PAIR ).
				and_return([ :the_entry ])
			
			@dir.get_entry( branch ).should == :the_entry
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
			@conn.should_receive( :search2 ).with( base, LDAP::LDAP_SCOPE_BASE, filter ).
				and_return( entries )

			# Turn found entries into Branch objects
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[0], @dir ).
				and_return( found_branch1 )
			Treequel::Branch.should_receive( :new_from_entry ).with( entries[1], @dir ).
				and_return( found_branch2 )

			@dir.search( base, :base, filter ).should == [ found_branch1, found_branch2 ]
		end


		it "can turn a DN string into an RDN string from its base" do
			@dir.rdn_to( TEST_PERSON_DN ).should == TEST_PERSON_DN.sub( /,#{TEST_BASE_DN}$/, '' )
		end
		
		it "implements a proxy method that allow for creation of branches" do
			rval = @dir.ou( :people )
			rval.dn.downcase.should == TEST_PEOPLE_DN.downcase
		end

		it "don't try to create sub-branches for method calls with more than one parameter" do
			lambda {
				@dir.dc( 'sbc', 'glar' )
			}.should raise_error( ArgumentError, /wrong number of arguments/ )
		end

		it "can fetch the server's schema" do
			@conn.should_receive( :schema ).and_return( :the_schema )
			@dir.schema.should == :the_schema
		end
		
		
	end
end


# vim: set nosta noet ts=4 sw=4:

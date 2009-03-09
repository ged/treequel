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
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants
# include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Directory do
	include Treequel::SpecHelpers
	
	before( :all ) do
		setup_logging( :debug )
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
	end
end


# vim: set nosta noet ts=4 sw=4:

#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel'
	require 'treequel/directory'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants


#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel do
	include Treequel::SpecHelpers

	before( :all ) do
		reset_logging()
	end

	it "should know if its default logger is replaced" do
		Treequel.reset_logger
		Treequel.should be_using_default_logger
		Treequel.logger = Logger.new( $stderr )
		Treequel.should_not be_using_default_logger
	end


	it "returns a version string if asked" do
		Treequel.version_string.should =~ /\w+ [\d.]+/
	end


	it "returns a version string with a build number if asked" do
		Treequel.version_string(true).should =~ /\w+ [\d.]+ \(build rev: \S+ \)/
	end


	it "provides a convenience method for creating directory objects" do
		Treequel::Directory.should_receive( :new ).and_return( :a_directory )
		Treequel.directory.should == :a_directory
	end

	it "accepts an LDAP url as the argument to the directory convenience method" do
		Treequel::Directory.should_receive( :new ).
			with({ :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com', :port => 389 }).
			and_return( :a_directory )
		Treequel.directory( 'ldap://ldap.example.com/dc=example,dc=com' ).should == :a_directory
	end

	it "raises an exception if #directory is called with a non-ldap URL" do
		lambda {
			Treequel.directory( 'http://example.com/' )
		}.should raise_error( ArgumentError, /ldap url/i )
	end

	it "accepts an options hash as the argument to the directory convenience method" do
		opts = { :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com' }
		Treequel::Directory.should_receive( :new ).with( opts ).
			and_return( :a_directory )
		Treequel.directory( opts ).should == :a_directory
	end

	it "can build an options hash from an LDAP URL" do
		Treequel.make_options_from_uri( 'ldap://ldap.example.com/dc=example,dc=com' ).should ==
			{ :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com', :port => 389 }
	end

	it "can build an options hash from an LDAPS URL" do
		Treequel.make_options_from_uri( 'ldaps://ldap.example.com/dc=example,dc=com' ).should ==
			{ :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com', :port => 636, :connect_type => :ssl }
	end

	it "can build an options hash from an LDAP URL without a host" do
		Treequel.make_options_from_uri( 'ldap:///dc=example,dc=com' ).should ==
			{ :base_dn => 'dc=example,dc=com', :port => 389 }
	end

	# [?<attrs>[?<scope>[?<filter>[?<extensions>]]]]
	it "can build an options hash from an LDAP URL with extra stuff" do
		uri = 'ldap:///dc=example,dc=com?uid=jrandom,ou=People?l?one?!bindname=cn=auth'
		Treequel.make_options_from_uri( uri ).should ==
			{ :base_dn => 'dc=example,dc=com', :port => 389 }
	end

	it "accepts a combination of URL and options hash as the argument to the directory " +
	   "convenience method" do
		uri = 'ldap://ldap.example.com/dc=example,dc=com'
		user_dn = 'cn=admin,dc=example,dc=com'
		pass = 'a:password!'
		options_hash = {
			:host         => 'ldap.example.com',
			:base_dn      => 'dc=example,dc=com',
			:port         => 389,
			:connect_type => :plain,
			:bind_dn      => user_dn,
			:pass         => pass,
		}

		Treequel::Directory.should_receive( :new ).
			with( options_hash ).
			and_return( :a_directory )

		Treequel.directory( uri, :bind_dn => user_dn, :pass => pass, :connect_type => :plain )
	end


	describe " logging subsystem" do
		before(:each) do
			Treequel.reset_logger
		end

		after(:each) do
			Treequel.reset_logger
		end


		it "has the default logger instance after being reset" do
			Treequel.logger.should equal( Treequel.default_logger )
		end

		it "has the default log formatter instance after being reset" do
			Treequel.logger.formatter.should equal( Treequel.default_log_formatter )
		end

	end


	describe " logging subsystem with new defaults" do
		before( :all ) do
			@original_logger = Treequel.default_logger
			@original_log_formatter = Treequel.default_log_formatter
		end

		after( :all ) do
			Treequel.default_logger = @original_logger
			Treequel.default_log_formatter = @original_log_formatter
		end


		it "uses the new defaults when the logging subsystem is reset" do
			logger = mock( "dummy logger", :null_object => true )
			formatter = mock( "dummy logger" )

			Treequel.default_logger = logger
			Treequel.default_log_formatter = formatter

			logger.should_receive( :formatter= ).with( formatter )

			Treequel.reset_logger
			Treequel.logger.should equal( logger )
		end

	end

end

# vim: set nosta noet ts=4 sw=4:

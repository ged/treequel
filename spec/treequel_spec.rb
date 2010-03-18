#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'treequel'
require 'treequel/directory'

include Treequel::TestConstants


#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
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
		Treequel.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
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


	it "provides a convenience method for creating directory objects from the system LDAP config" do
		Treequel.should_receive( :find_configfile ).and_return( :a_configfile_path )
		Treequel.should_receive( :read_opts_from_config ).with( :a_configfile_path ).
			and_return({ :configfile_opts => 1 })
		Treequel.should_receive( :read_opts_from_environment ).
			and_return({ :environment_opts => 1 })

		merged_config = Treequel::Directory::DEFAULT_OPTIONS.
			merge({ :configfile_opts => 1, :environment_opts => 1 })

		Treequel::Directory.should_receive( :new ).with( merged_config ).
			and_return( :a_directory )

		Treequel.directory_from_config.should == :a_directory
	end


	describe "system LDAP config methods" do

		before( :each ) do
			ENV['LDAPCONF']   = nil
			ENV['LDAPRC']     = nil
			ENV['LDAPURI']    = nil
			ENV['LDAPBASE']   = nil
			ENV['LDAPBINDDN'] = nil
			ENV['LDAPHOST']   = nil
			ENV['LDAPPORT']   = nil
		end


		it "uses the LDAPCONF environment variable if it is set" do
			configpath = mock( "configfile Pathname object" )
			ENV['LDAPCONF'] = 'a_configfile_path'

			Treequel.should_receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			configpath.should_receive( :expand_path ).and_return( configpath )
			configpath.should_receive( :readable? ).and_return( true )

			Treequel.find_configfile.should == configpath
		end

		it "raises an exception if the file specified in LDAPCONF isn't readable" do
			configpath = mock( "configfile Pathname object" )
			ENV['LDAPCONF'] = 'a_configfile_path'

			Treequel.should_receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			configpath.should_receive( :expand_path ).and_return( configpath )
			configpath.should_receive( :readable? ).and_return( false )

			expect {
				Treequel.find_configfile
			}.to raise_exception( RuntimeError, /a_configfile_path.*LDAPCONF/ )
		end

		it "uses the LDAPRC environment variable if it is set and LDAPCONF isn't" do
			configpath = mock( "configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			Treequel.should_receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			configpath.should_receive( :expand_path ).and_return( configpath )
			configpath.should_receive( :readable? ).and_return( true )

			Treequel.find_configfile.should == configpath
		end

		it "looks in the current user's HOME for the LDAPRC file if it isn't in the CWD" do
			cwd_path = mock( "CWD configfile Pathname object" )
			homedir_path = mock( "HOME configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			Treequel.should_receive( :Pathname ).with( 'a_configfile_path' ).and_return( cwd_path )
			cwd_path.should_receive( :expand_path ).and_return( cwd_path )
			cwd_path.should_receive( :readable? ).and_return( false )

			Treequel.should_receive( :Pathname ).with( '~' ).and_return( homedir_path )
			homedir_path.should_receive( :expand_path ).and_return( homedir_path )
			homedir_path.should_receive( :+ ).with( 'a_configfile_path' ).and_return( homedir_path )
			homedir_path.should_receive( :readable? ).and_return( true )

			Treequel.find_configfile.should == homedir_path
		end

		it "raises an exception if the file specified in LDAPRC isn't readable" do
			cwd_path = mock( "CWD configfile Pathname object" )
			homedir_path = mock( "HOME configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			Treequel.should_receive( :Pathname ).with( 'a_configfile_path' ).and_return( cwd_path )
			cwd_path.should_receive( :expand_path ).and_return( cwd_path )
			cwd_path.should_receive( :readable? ).and_return( false )

			Treequel.should_receive( :Pathname ).with( '~' ).and_return( homedir_path )
			homedir_path.should_receive( :expand_path ).and_return( homedir_path )
			homedir_path.should_receive( :+ ).with( 'a_configfile_path' ).and_return( homedir_path )
			homedir_path.should_receive( :readable? ).and_return( false )

			expect {
				Treequel.find_configfile
			}.to raise_exception( RuntimeError, /a_configfile_path.*LDAPRC/ )
		end

		it "searches a list of common ldap.conf paths if neither LDAPCONF nor LDAPRC are set" do
			pathmocks = []

			Treequel::COMMON_LDAP_CONF_PATHS.each do |path|
				pathname = mock( "pathname: #{path}" )
				pathmocks << pathname
			end
			Treequel.should_receive( :Pathname ).and_return( *pathmocks )

			# Index of the entry we're going to pretend exists
			successful_index = 6
			0.upto( successful_index ) do |i|
				pathmocks[i].should_receive( :readable? ).and_return( i == successful_index )
			end

			Treequel.find_configfile.should == pathmocks[ successful_index ]
		end

		it "maps the OpenLDAP URI directive to equivalent options" do
			File.should_receive( :readlines ).with( :a_configfile ).
				and_yield( "URI ldap://ldap.acme.com/dc=acme,dc=com" )
			Treequel.read_opts_from_config( :a_configfile ).should ==
				{ :port => 389, :base_dn => "dc=acme,dc=com", :host => "ldap.acme.com" }
		end

		it "maps the OpenLDAP BASE directive to the base_dn option" do
			File.should_receive( :readlines ).with( :a_configfile ).
				and_yield( "BASE dc=acme,dc=com" )
			Treequel.read_opts_from_config( :a_configfile ).should == 
				{ :base_dn => "dc=acme,dc=com" }
		end

		it "maps the OpenLDAP BINDDN directive to the bind_dn option" do
			File.should_receive( :readlines ).with( :a_configfile ).
				and_yield( "BINDDN cn=admin,dc=acme,dc=com" )
			Treequel.read_opts_from_config( :a_configfile ).should ==
				{ :bind_dn => "cn=admin,dc=acme,dc=com" }
		end

		it "maps the OpenLDAP HOST directive to the host option" do
			File.should_receive( :readlines ).with( :a_configfile ).
				and_yield( "# Host file\nHOST ldap.acme.com\n\n" )
			Treequel.read_opts_from_config( :a_configfile ).should ==
				{ :host => 'ldap.acme.com' }
		end

		it "maps the OpenLDAP PORT directive to the port option" do
			File.should_receive( :readlines ).with( :a_configfile ).
				and_yield( "PORT 389" )
			Treequel.read_opts_from_config( :a_configfile ).should ==
				{ :port => 389 }
		end


		it "maps nss-style options correctly"

		it "maps the OpenLDAP LDAPURI environment variable to equivalent options" do
			ENV['LDAPURI'] = 'ldaps://quomsohutch.linkerlinlinkin.org/o=linkerlickin'
			Treequel.read_opts_from_environment.should == {
				:host         => 'quomsohutch.linkerlinlinkin.org',
				:connect_type => :ssl,
				:port         => 636,
				:base_dn      => 'o=linkerlickin'
			  }
		end

		it "maps the OpenLDAP LDAPBASE environment variable to the base_dn option" do
			ENV['LDAPBASE'] = 'o=linkerlickin'
			Treequel.read_opts_from_environment.should == {
				:base_dn => 'o=linkerlickin'
			  }
		end

		it "maps the OpenLDAP LDAPBINDDN environment variable to the bind_dn option" do
			ENV['LDAPBINDDN'] = 'cn=superuser,ou=people,o=linkerlickin'
			Treequel.read_opts_from_environment.should == {
				:bind_dn => 'cn=superuser,ou=people,o=linkerlickin'
			  }
		end

		it "maps the OpenLDAP LDAPHOST environment variable to the host option" do
			ENV['LDAPHOST'] = 'quomsohutch.linkerlinlinkin.org'
			Treequel.read_opts_from_environment.should == {
				:host => 'quomsohutch.linkerlinlinkin.org',
			  }
		end

		it "maps the OpenLDAP LDAPPORT environment variable to the port option" do
			ENV['LDAPPORT'] = '636'
			Treequel.read_opts_from_environment.should == {
				:port => 636,
			  }
		end
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

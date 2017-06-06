# -*- ruby -*-
#encoding: utf-8

require_relative 'spec_helpers'

require 'treequel'
require 'treequel/directory'


describe Treequel do
	include Treequel::SpecHelpers

	it "should know if its default logger is replaced" do
		begin
			Treequel.reset_logger
			expect( Treequel ).to be_using_default_logger
			Treequel.logger = Logger.new( $stderr )
			expect( Treequel ).to_not be_using_default_logger
		ensure
			Treequel.reset_logger
		end
	end


	it "returns a version string if asked" do
		expect( Treequel.version_string ).to match( /\w+ [\d.]+/ )
	end


	it "returns a version string with a build number if asked" do
		expect( Treequel.version_string(true) ).to match( /\w+ [\d.]+ \(build [[:xdigit:]]+\)/ )
	end


	it "provides a convenience method for creating directory objects" do
		expect( Treequel::Directory ).to receive( :new ).and_return( :a_directory )
		expect( Treequel.directory ).to eq( :a_directory )
	end

	it "accepts an LDAP url as the argument to the directory convenience method" do
		expect( Treequel::Directory ).to receive( :new ).
			with({ :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com', :port => 389 }).
			and_return( :a_directory )
		expect( Treequel.directory( 'ldap://ldap.example.com/dc=example,dc=com' ) ).to eq( :a_directory )
	end

	it "raises an exception if #directory is called with a non-ldap URL" do
		expect {
			Treequel.directory( 'http://example.com/' )
		}.to raise_error( ArgumentError, /ldap url/i )
	end

	it "accepts an options hash as the argument to the directory convenience method" do
		opts = { :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com' }
		expect( Treequel::Directory ).to receive( :new ).with( opts ).
			and_return( :a_directory )
		expect( Treequel.directory( opts ) ).to eq( :a_directory )
	end

	it "can build an options hash from an LDAP URL" do
		expect( Treequel.make_options_from_uri('ldap://ldap.example.com/dc=example,dc=com') ).
			to include( :host => 'ldap.example.com', :base_dn => 'dc=example,dc=com', :port => 389 )
	end

	it "can build an options hash from an LDAPS URL" do
		expect( Treequel.make_options_from_uri('ldaps://ldap.example.com/dc=example,dc=com') ).
			to include(
				 :host => 'ldap.example.com',
				 :base_dn => 'dc=example,dc=com',
				 :port => 636,
				 :connect_type => :ssl
			)
	end

	it "can build an options hash from an LDAP URL without a host" do
		expect( Treequel.make_options_from_uri('ldap:///dc=example,dc=com') ).
			to include( :base_dn => 'dc=example,dc=com', :port => 389 )
	end

	it "uses the LDAPS port for ldaps:// URIs" do
		expect( Treequel.make_options_from_uri('ldaps:///dc=example,dc=com') ).
			to include( :base_dn => 'dc=example,dc=com', :connect_type => :ssl, :port => 636 )
	end

	# [?<attrs>[?<scope>[?<filter>[?<extensions>]]]]
	it "can build an options hash from an LDAP URL with extra stuff" do
		uri = 'ldap:///dc=example,dc=com?uid=jrandom,ou=People?l?one?!bindname=cn=auth'
		expect( Treequel.make_options_from_uri( uri ) ).
			to include( :base_dn => 'dc=example,dc=com', :port => 389 )
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

		expect( Treequel::Directory ).to receive( :new ).
			with( options_hash ).
			and_return( :a_directory )

		Treequel.directory( uri, :bind_dn => user_dn, :pass => pass, :connect_type => :plain )
	end

	it "raises an exception when ::directory is called with something other than a Hash, " +
	   "String, or URI" do
		expect {
			Treequel.directory( 2 )
		}.to raise_exception( ArgumentError, /unknown directory option/i )
	end

	it "provides a convenience method for creating directory objects from the system LDAP config" do
		expect( Treequel ).to receive( :find_configfile ).and_return( :a_configfile_path )
		expect( Treequel ).to receive( :read_opts_from_config ).with( :a_configfile_path ).
			and_return({ :configfile_opts => 1 })
		expect( Treequel ).to receive( :read_opts_from_environment ).
			and_return({ :environment_opts => 1 })

		merged_config = Treequel::Directory::DEFAULT_OPTIONS.
			merge({ :configfile_opts => 1, :environment_opts => 1 })

		expect( Treequel::Directory ).to receive( :new ).with( merged_config ).
			and_return( :a_directory )

		expect( Treequel.directory_from_config ).to eq( :a_directory )
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

		after( :all ) do
			reset_logging()
		end

		it "uses the LDAPCONF environment variable if it is set" do
			configpath = double( "configfile Pathname object" )
			ENV['LDAPCONF'] = 'a_configfile_path'

			expect( Treequel ).to receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			expect( configpath ).to receive( :expand_path ).and_return( configpath )
			expect( configpath ).to receive( :readable? ).and_return( true )

			expect( Treequel.find_configfile ).to eq( configpath )
		end

		it "raises an exception if the file specified in LDAPCONF isn't readable" do
			configpath = double( "configfile Pathname object" )
			ENV['LDAPCONF'] = 'a_configfile_path'

			expect( Treequel ).to receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			expect( configpath ).to receive( :expand_path ).and_return( configpath )
			expect( configpath ).to receive( :readable? ).and_return( false )

			expect {
				Treequel.find_configfile
			}.to raise_exception( RuntimeError, /a_configfile_path.*LDAPCONF/ )
		end

		it "uses the LDAPRC environment variable if it is set and LDAPCONF isn't" do
			configpath = double( "configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			expect( Treequel ).to receive( :Pathname ).with( 'a_configfile_path' ).and_return( configpath )
			expect( configpath ).to receive( :expand_path ).and_return( configpath )
			expect( configpath ).to receive( :readable? ).and_return( true )

			expect( Treequel.find_configfile ).to eq( configpath )
		end

		it "looks in the current user's HOME for the LDAPRC file if it isn't in the CWD" do
			cwd_path = double( "CWD configfile Pathname object" )
			homedir_path = double( "HOME configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			expect( Treequel ).to receive( :Pathname ).with( 'a_configfile_path' ).and_return( cwd_path )
			expect( cwd_path ).to receive( :expand_path ).and_return( cwd_path )
			expect( cwd_path ).to receive( :readable? ).and_return( false )

			expect( Treequel ).to receive( :Pathname ).with( '~' ).and_return( homedir_path )
			expect( homedir_path ).to receive( :expand_path ).and_return( homedir_path )
			expect( homedir_path ).to receive( :+ ).with( 'a_configfile_path' ).and_return( homedir_path )
			expect( homedir_path ).to receive( :readable? ).and_return( true )

			expect( Treequel.find_configfile ).to eq( homedir_path )
		end

		it "raises an exception if the file specified in LDAPRC isn't readable" do
			cwd_path = double( "CWD configfile Pathname object" )
			homedir_path = double( "HOME configfile Pathname object" )
			ENV['LDAPRC'] = 'a_configfile_path'

			expect( Treequel ).to receive( :Pathname ).with( 'a_configfile_path' ).and_return( cwd_path )
			expect( cwd_path ).to receive( :expand_path ).and_return( cwd_path )
			expect( cwd_path ).to receive( :readable? ).and_return( false )

			expect( Treequel ).to receive( :Pathname ).with( '~' ).and_return( homedir_path )
			expect( homedir_path ).to receive( :expand_path ).and_return( homedir_path )
			expect( homedir_path ).to receive( :+ ).with( 'a_configfile_path' ).and_return( homedir_path )
			expect( homedir_path ).to receive( :readable? ).and_return( false )

			expect {
				Treequel.find_configfile
			}.to raise_exception( RuntimeError, /a_configfile_path.*LDAPRC/ )
		end

		it "searches a list of common ldap.conf paths if neither LDAPCONF nor LDAPRC are set" do
			pathmocks = []

			Treequel::COMMON_LDAP_CONF_PATHS.each do |path|
				pathname = double( "pathname: #{path}" )
				pathmocks << pathname
			end
			expect( Treequel ).to receive( :Pathname ).and_return( *pathmocks )

			# Index of the entry we're going to pretend exists
			successful_index = 6
			0.upto( successful_index ) do |i|
				expect( pathmocks[i] ).to receive( :readable? ).and_return( i == successful_index )
			end

			expect( Treequel.find_configfile ).to eq( pathmocks[ successful_index ] )
		end

		# 
		# OpenLDAP-style config
		# 

		it "maps the OpenLDAP URI directive to equivalent options" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "URI ldap://ldap.acme.com/dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :port => 389, :base_dn => "dc=acme,dc=com", :host => "ldap.acme.com" )
		end

		it "maps the OpenLDAP BASE directive to the base_dn option" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "BASE dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :base_dn => "dc=acme,dc=com" )
		end

		it "maps the OpenLDAP BINDDN directive to the bind_dn option" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "BINDDN cn=admin,dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :bind_dn => "cn=admin,dc=acme,dc=com" )
		end

		it "maps the OpenLDAP HOST directive to the host option" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "# Host file\nHOST ldap.acme.com\n\n" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :host => 'ldap.acme.com' )
		end

		it "maps the OpenLDAP PORT directive to the port option" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "PORT 389" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :port => 389 )
		end

		# 
		# NSS-style config
		# 

		it "maps the nss-style uri directive to equivalent options" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "uri ldap://ldap.acme.com/dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :port => 389, :base_dn => "dc=acme,dc=com", :host => "ldap.acme.com" )
		end

		it "maps the nss-style 'host' option correctly" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "host ldap.acme.com\n\n" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to include( :host => 'ldap.acme.com' )
		end

		it "maps the nss-style 'binddn' option correctly" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "binddn cn=superuser,dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :bind_dn => "cn=superuser,dc=acme,dc=com" )
		end

		it "maps the nss-style 'bindpw' option correctly" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "# My totally awesome password" ).
				and_yield( "bindpw a:password!" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :pass => "a:password!" )
		end

		it "maps the nss-style 'base' option correctly" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "base dc=acme,dc=com" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :base_dn => "dc=acme,dc=com" )
		end

		it "maps the nss-style 'ssl' option to the correct port and connect_type if it's 'off'" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "ssl  off" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :port => 389, :connect_type => :plain )
		end

		it "maps the nss-style 'ssl' option to the correct port and connect_type if " +
		   "it's 'start_tls'" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( '' ).
				and_yield( '# Use TLS' ).
				and_yield( 'ssl start_tls' )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :port => 389, :connect_type => :tls )
		end

		it "maps the nss-style 'ssl' option to the correct port and connect_type if " +
		   "it's 'on'" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "\n# Use plain SSL\nssl on\n" )
			expect( Treequel.read_opts_from_config(:a_configfile) ).
				to eq( :port => 636, :connect_type => :ssl )
		end

		it "ignores nss-style 'ssl' option if it is set to something other than " +
		   "'on', 'off', or 'start_tls'" do
			expect( IO ).to receive( :foreach ).with( :a_configfile ).
				and_yield( "\n# Use alien-invasion protocol\nssl aliens\n" )

			expect {
				Treequel.read_opts_from_config( :a_configfile )
			}.to_not raise_exception()
		end

		# 
		# Environment
		# 

		it "maps the OpenLDAP LDAPURI environment variable to equivalent options" do
			ENV['LDAPURI'] = 'ldaps://quomsohutch.linkerlinlinkin.org/o=linkerlickin'
			expect( Treequel.read_opts_from_environment ).to include(
				:host         => 'quomsohutch.linkerlinlinkin.org',
				:connect_type => :ssl,
				:port         => 636,
				:base_dn      => 'o=linkerlickin'
			)
		end

		it "maps the OpenLDAP LDAPBASE environment variable to the base_dn option" do
			ENV['LDAPBASE'] = 'o=linkerlickin'
			expect( Treequel.read_opts_from_environment ).to include(
				:base_dn => 'o=linkerlickin'
			)
		end

		it "maps the OpenLDAP LDAPBINDDN environment variable to the bind_dn option" do
			ENV['LDAPBINDDN'] = 'cn=superuser,ou=people,o=linkerlickin'
			expect( Treequel.read_opts_from_environment ).to include(
				:bind_dn => 'cn=superuser,ou=people,o=linkerlickin'
			)
		end

		it "maps the OpenLDAP LDAPHOST environment variable to the host option" do
			ENV['LDAPHOST'] = 'quomsohutch.linkerlinlinkin.org'
			expect( Treequel.read_opts_from_environment ).to include(
				:host => 'quomsohutch.linkerlinlinkin.org'
			)
		end

		it "maps the OpenLDAP LDAPPORT environment variable to the port option" do
			ENV['LDAPPORT'] = '636'
			expect( Treequel.read_opts_from_environment ).to include(
				:port => 636
			)
		end
	end


end

# vim: set nosta noet ts=4 sw=4:

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

	require 'treequel/connection'
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

describe Treequel::Connection do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	before( :each ) do
	end


	it "delegates methods to an underlying connection object" do
		ldapconn = mock( "LDAP::Conn object" )
		LDAP::SSLConn.should_receive( :new ).with( TEST_HOST, TEST_PORT, true ).
			and_return( ldapconn )
		ldapconn.should_receive( :set_option ).with( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
		ldapconn.should_receive( :root_dse ).and_return( TEST_DSE )

		conn = Treequel::Connection.new( TEST_HOST, TEST_PORT )
		conn.root_dse.should == TEST_DSE
	end


	it "re-raises plain RuntimeErrors raised during delegated calls as more-interesting " +
	   "exception types" do
		
	end

	it "attempts to re-establish its connection if the current one indicates it's no longer valid"
	it "stops trying to re-establish a connection if it's tried too many times within a certain " +
	   "time period"

	it "connects to the referred server and-reruns any method that raises a Referral"
	it ""

end


# vim: set nosta noet ts=4 sw=4:

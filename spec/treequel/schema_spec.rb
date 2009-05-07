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

	require 'treequel/schema'
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

describe Treequel::Schema do
	include Treequel::SpecHelpers

	SIMPLE_OBJECTCLASS = %{( 2.5.6.0 NAME 'top' DESC 'top of the superclass chain' ABSTRACT MUST objectClass )}

	before( :all ) do
		setup_logging( :debug )
	end

	after( :all ) do
		reset_logging()
	end


	it "can parse LAIKA's objectclasses" do
		pending "completion of the objectClass parser"
		objectClass = Treequel::Schema.parse_objectclass( SIMPLE_OBJECTCLASS )
		objectClass.should be_a( Struct )
	end

	it "can parse the schema structure returned from LDAP::Conn#schema"
	it "can return the MUST attributes for an objectClass"
	it "can return the MAY attributes for an objectClass"


end


# vim: set nosta noet ts=4 sw=4:

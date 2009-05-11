#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'yaml'
	require 'ldap'
	require 'ldap/schema'
	require 'treequel/schema/objectclass'
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

describe Treequel::Schema::ObjectClass do
	include Treequel::SpecHelpers

	TOP_OBJECTCLASS = %{( 2.5.6.0 NAME 'top' DESC 'top of the superclass chain' ABSTRACT MUST objectClass )}

	before( :all ) do
		setup_logging( :debug )
		@datadir = Pathname( __FILE__ ).dirname.parent.parent + 'data'
	end

	before( :each ) do
		@oc = Treequel::Schema::ObjectClass.parse( TOP_OBJECTCLASS )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'top' objectClass" do
		it "knows what OID corresponds to the class" do
			@oc.oid.should == '2.5.6.0'
		end

		it "knows that it has one MUST attribute" do
			@oc.must.should have( 1 ).member
			@oc.must.should == [ :objectClass ]
		end

		it "knows that it doesn't have any MAY attributes" do
			@oc.may.should be_empty()
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

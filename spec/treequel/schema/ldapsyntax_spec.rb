#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/ldapsyntax'


include Treequel::TestConstants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::LDAPSyntax do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@schema = mock( "treequel schema object" )
	end

	after( :all ) do
		reset_logging()
	end


	describe "parsed from the 'Boolean' syntax" do

		BOOLEAN_SYNTAX = %{( 1.3.6.1.4.1.1466.115.121.1.7 DESC 'Boolean' )}

		before( :each ) do
			@syntax = Treequel::Schema::LDAPSyntax.parse( @schema, BOOLEAN_SYNTAX )
		end

		it "knows what its OID is" do
			@syntax.oid.should == '1.3.6.1.4.1.1466.115.121.1.7'
		end

		it "knows what its DESC attribute is" do
			@syntax.desc.should == 'Boolean'
		end

		it "can remake its own schema description" do
			@syntax.to_s.should == BOOLEAN_SYNTAX
		end
	end


	describe "parsed from a syntax with no DESC" do
		NODESC_SYNTAX = %{( 1.3.6.1.4.1.1466.115.121.1.14 )}

		before( :each ) do
			@syntax = Treequel::Schema::LDAPSyntax.parse( @schema, NODESC_SYNTAX )
		end

		it "knows what its OID is" do
			@syntax.oid.should == '1.3.6.1.4.1.1466.115.121.1.14'
		end

		it "knows that it doesn't have a DESC attribute" do
			@syntax.desc.should be_nil()
		end

		it "can remake its own schema description" do
			@syntax.to_s.should == NODESC_SYNTAX
		end
	end

end


# vim: set nosta noet ts=4 sw=4:

#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'time'
require 'rspec'

require 'spec/lib/helpers'

require 'treequel'
require 'treequel/utils'


include Treequel::TestConstants
# include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::LDAPControlExtensions do
	describe "equality operator method" do

		it "causes LDAP::Controls with the same class, OID, value, and criticality to " +
		   "compare as equal" do
			control1 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )
			control2 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )

			control1.should == control2
		end

		it "causes LDAP::Controls with different classes to compare as inequal" do
			control_subclass = Class.new( LDAP::Control )
			control1 = control_subclass.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )
			control2 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )

			control1.should_not == control2
		end

		it "causes LDAP::Controls with different OIDs to compare as inequal" do
			control1 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )
			control2 = LDAP::Control.new( CONTROL_OIDS[:incremental_values], "0\003\n\001\003", true )

			control1.should_not == control2
		end

		it "causes LDAP::Controls with different values to compare as inequal" do
			control1 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )
			control2 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\001", true )

			control1.should_not == control2
		end

		it "causes LDAP::Controls with different criticality to compare as inequal" do
			control1 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", true )
			control2 = LDAP::Control.new( CONTROL_OIDS[:sync], "0\003\n\001\003", false )

			control1.should_not == control2
		end

	end
end # module Treequel::LDAPControlExtensions


describe Treequel::TimeExtensions do

	before( :all ) do
		# Make the local timezone PDT so offsets show up correctly
		@real_tz = ENV['TZ']
		ENV['TZ'] = 'US/Pacific'
	end

	before( :each ) do
		@time = Time.parse( "Fri Aug 20 08:21:35.1876455 -0700 2010" )
	end

	after( :all ) do
		ENV['TZ'] = @real_tz
	end

	describe "RFC4517 LDAP Generalized Time method" do

		it "returns the time in 'Generalized Time' format" do
			@time.ldap_generalized.should == "20100820082135-0700"
		end

		it "can include fractional seconds if the optional fractional digits argument is given" do
			@time.ldap_generalized( 3 ).should == "20100820082135.187-0700"
		end

		it "doesn't include the decimal if fractional digits is specified but zero" do
			@time.ldap_generalized( 0 ).should == "20100820082135-0700"
		end

		it "zero-fills any digits after six in the fractional digits" do
			@time.ldap_generalized( 11 ).should == "20100820082135.18764500000-0700"
		end

		it "uses 'Z' for the timezone of times in UTC" do
			@time.utc.ldap_generalized.should == "20100820152135Z"
		end

	end

	describe "RFC4517 UTC Time method" do

		it "returns the time in 'UTC Time' format" do
			@time.ldap_utc.should == "100820082135-0700"
		end

		it "uses 'Z' for the timezone of times in UTC" do
			@time.utc.ldap_utc.should == "100820152135Z"
		end

	end

end


describe Treequel::DateExtensions do

	before( :all ) do
		# Make the local timezone PDT so offsets show up correctly
		@real_tz = ENV['TZ']
		ENV['TZ'] = ':GMT'
	end

	before( :each ) do
		@date = Date.parse( "2010-08-05" )
	end

	after( :all ) do
		ENV['TZ'] = @real_tz
	end

	describe "RFC4517 LDAP Generalized Time method" do

		it "returns the time in 'Generalized Time' format" do
			@date.ldap_generalized.should == "20100805000001+0000"
		end

		it "can include fractional seconds if the optional fractional digits argument is given" do
			@date.ldap_generalized( 3 ).should == "20100805000001.000+0000"
		end

		it "doesn't include the decimal if fractional digits is specified but zero" do
			@date.ldap_generalized( 0 ).should == "20100805000001+0000"
		end

		it "zero-fills any digits after six in the fractional digits" do
			@date.ldap_generalized( 11 ).should == "20100805000001.00000000000+0000"
		end

	end

	describe "RFC4517 UTC Time method" do

		it "returns the time in 'UTC Time' format" do
			@date.ldap_utc.should == "100805000001+0000"
		end

	end

end


# vim: set nosta noet ts=4 sw=4:

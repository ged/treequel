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

	require 'yaml'
	require 'ldap'
	require 'ldap/schema'
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

describe Treequel::Schema::Table do
	include Treequel::SpecHelpers


	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		@table = Treequel::Schema::Table.new
	end

	after( :all ) do
		reset_logging()
	end


	it "allows setting/fetching case-insensitively" do
		@table['organizationalRole'] = :or
		@table["apple-preset-computer-list"] = :applepreset
		@table.deltaCRL = :deltacrl

		@table['organizationalrole'].should == :or
		@table[:organizationalrole].should == :or
		@table.organizationalRole.should == :or
		@table.organizationalrole.should == :or

		@table[:"apple-preset-computer-list"].should == :applepreset
		@table['apple-preset-computer-list'].should == :applepreset
		@table[:apple_preset_computer_list].should == :applepreset
		@table.apple_preset_computer_list.should == :applepreset

		@table['deltacrl'].should == :deltacrl
		@table[:deltaCRL].should == :deltacrl
		@table[:deltacrl].should == :deltacrl
		@table.deltaCRL.should == :deltacrl
		@table.deltacrl.should == :deltacrl

	end


	it "doesn't try to normalize numeric OIDs" do
		@table['1.3.6.1.4.1.4203.666.11.1.4.2.1.2'] = :an_oid
		@table['1.3.6.1.4.1.4203.666.11.1.4.2.1.2'].should == :an_oid
		@table['13614142036661114212'].should_not == :an_oid
		@table.keys.should include( '1.3.6.1.4.1.4203.666.11.1.4.2.1.2' )
	end


	it "merges other Tables" do
		othertable = Treequel::Schema::Table.new

		@table['ou'] = 'thing'
		@table['cn'] = 'chunker'

		othertable['cn'] = 'phunker'

		ot = @table.merge( othertable )
		ot['ou'].should == 'thing'
		ot['cn'].should == 'phunker'
	end


	it "merges hashes after normalizing keys" do
		@table['ou'] = 'thing'
		@table['apple-computer-list'] = 'trishtrash'

		hash = { 'apple-computer-list' => 'pinhash' }

		ot = @table.merge( hash )
		ot['ou'].should == 'thing'
		ot['apple-computer-list'].should == 'pinhash'
	end


	it "dupes its inner hash when duped" do
		newtable = @table.dup

		newtable[:cn] = 'god'
		@table.should_not include( :cn )
		@table.should be_empty()
	end


	it "provides a case-insensitive version of #values_at" do
		@table[:cn]      = 'contra_rules'
		@table[:d]       = 'ghosty'
		@table[:porntipsGuzzardo] = 'cha-ching'

		results = @table.values_at( :CN, 'PornTipsGuzzARDO' )
		results.should include( 'contra_rules' )
		results.should include( 'cha-ching' )
		results.should_not include( 'ghosty' )
	end

end



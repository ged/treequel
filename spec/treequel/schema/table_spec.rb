#!/usr/bin/env ruby

require_relative '../../spec_helpers'


require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema'


include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Schema::Table do
	include Treequel::SpecHelpers


	let( :table ) { described_class.new }


	it "allows setting/fetching case-insensitively" do
		table['organizationalRole'] = :or
		table["apple-preset-computer-list"] = :applepreset
		table.deltaCRL = :deltacrl

		expect( table['organizationalrole'] ).to eq( :or )
		expect( table[:organizationalrole] ).to eq( :or )
		expect( table.organizationalRole ).to eq( :or )
		expect( table.organizationalrole ).to eq( :or )

		expect( table[:"apple-preset-computer-list"] ).to eq( :applepreset )
		expect( table['apple-preset-computer-list'] ).to eq( :applepreset )
		expect( table[:apple_preset_computer_list] ).to eq( :applepreset )
		expect( table.apple_preset_computer_list ).to eq( :applepreset )

		expect( table['deltacrl'] ).to eq( :deltacrl )
		expect( table[:deltaCRL] ).to eq( :deltacrl )
		expect( table[:deltacrl] ).to eq( :deltacrl )
		expect( table.deltaCRL ).to eq( :deltacrl )
		expect( table.deltacrl ).to eq( :deltacrl )

	end


	it "doesn't try to normalize numeric OIDs" do
		table['1.3.6.1.4.1.4203.666.11.1.4.2.1.2'] = :an_oid
		expect( table['1.3.6.1.4.1.4203.666.11.1.4.2.1.2'] ).to eq( :an_oid )
		expect( table['13614142036661114212'] ).to_not eq( :an_oid )
		expect( table.keys ).to include( '1.3.6.1.4.1.4203.666.11.1.4.2.1.2' )
	end


	it "merges other Tables" do
		othertable = Treequel::Schema::Table.new

		table['ou'] = 'thing'
		table['cn'] = 'chunker'

		othertable['cn'] = 'phunker'

		ot = table.merge( othertable )
		expect( ot['ou'] ).to eq( 'thing' )
		expect( ot['cn'] ).to eq( 'phunker' )
	end


	it "merges hashes after normalizing keys" do
		table['ou'] = 'thing'
		table['apple-computer-list'] = 'trishtrash'

		hash = { 'apple-computer-list' => 'pinhash' }

		ot = table.merge( hash )
		expect( ot['ou'] ).to eq( 'thing' )
		expect( ot['apple-computer-list'] ).to eq( 'pinhash' )
	end


	it "dupes its inner hash when duped" do
		newtable = table.dup

		newtable[:cn] = 'god'
		expect( table ).to_not include( :cn )
		expect( table ).to be_empty()
	end


	it "provides a case-insensitive version of #values_at" do
		table[:cn]               = 'contra_rules'
		table[:d]                = 'ghosty'
		table[:porntipsGuzzardo] = 'cha-ching'

		results = table.values_at( :CN, 'PornTipsGuzzARDO' )
		expect( results ).to include( 'contra_rules' )
		expect( results ).to include( 'cha-ching' )
		expect( results ).to_not include( 'ghosty' )
	end

	it "can iterate over its members" do
		table[:cn]               = 'contra_rules'
		table[:d]                = 'ghosty'
		table[:porntipsGuzzardo] = 'cha-ching'

		collection = []
		table.each {|k,v| collection << [k,v] }
		expect( collection.transpose[0] ).to include( :cn, :d, :porntipsguzzardo )
		expect( collection.transpose[1] ).to include( 'contra_rules', 'ghosty', 'cha-ching' )
	end

	it "is Enumerable" do
		table[:cn]               = 'contra_rules'
		table[:d]                = 'ghosty'
		table[:porntipsGuzzardo] = 'cha-ching'

		collection = []
		expect( table.any? {|k,v| v.index('o') } ).to eq( true )
	end

end



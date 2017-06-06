# -*- ruby -*-
#encoding: utf-8

require_relative '../../spec_helpers'

require 'yaml'
require 'ldap'
require 'ldap/schema'
require 'treequel/schema/ldapsyntax'


describe Treequel::Schema::LDAPSyntax do
	include Treequel::SpecHelpers


	before( :each ) do
		@schema = double( "treequel schema object" )
	end


	describe "parsed from the 'Boolean' syntax" do

		BOOLEAN_SYNTAX = %{( 1.3.6.1.4.1.1466.115.121.1.7 DESC 'Boolean' )}

		before( :each ) do
			@syntax = Treequel::Schema::LDAPSyntax.parse( @schema, BOOLEAN_SYNTAX )
		end

		it "knows what its OID is" do
			expect( @syntax.oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.7' )
		end

		it "knows what its DESC attribute is" do
			expect( @syntax.desc ).to eq( 'Boolean' )
		end

		it "can remake its own schema description" do
			expect( @syntax.to_s ).to eq( BOOLEAN_SYNTAX )
		end
	end


	describe "parsed from a syntax with no DESC" do
		NODESC_SYNTAX = %{( 1.3.6.1.4.1.1466.115.121.1.14 )}

		before( :each ) do
			@syntax = Treequel::Schema::LDAPSyntax.parse( @schema, NODESC_SYNTAX )
		end

		it "knows what its OID is" do
			expect( @syntax.oid ).to eq( '1.3.6.1.4.1.1466.115.121.1.14' )
		end

		it "knows that it doesn't have a DESC attribute" do
			expect( @syntax.desc ).to be_nil()
		end

		it "can remake its own schema description" do
			expect( @syntax.to_s ).to eq( NODESC_SYNTAX )
		end
	end

end


# vim: set nosta noet ts=4 sw=4:

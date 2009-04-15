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

	require 'treequel/filter'
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

describe Treequel::Filter do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can be created from a string literal" do
		Treequel::Filter.new( '(uid=bargrab)' ).to_s.should == '(uid=bargrab)'
	end

	it "wraps string literal instances in parens if it requires them" do
		Treequel::Filter.new( 'uid=bargrab' ).to_s.should == '(uid=bargrab)'
	end

	it "defaults to selecting everything" do
		Treequel::Filter.new.to_s.should == '(objectClass=*)'
	end

	it "parses a single Symbol argument as a presence filter" do
		Treequel::Filter.new( :uid ).to_s.should == '(uid=*)'
	end

	it "parses a single-element Array with a Symbol as a presence filter" do
		Treequel::Filter.new( [:uid] ).to_s.should == '(uid=*)'
	end

	it "parses a Symbol+value pair as a simple item equal filter" do
		Treequel::Filter.new( :uid, 'bigthung' ).to_s.should == '(uid=bigthung)'
	end

	it "parses a Symbol+value pair in an Array as a simple item equal filter" do
		Treequel::Filter.new( [:uid, 'bigthung'] ).to_s.should == '(uid=bigthung)'
	end

	it "parses an AND expression with only a single clause" do
		Treequel::Filter.new( [:&, [:uid, 'kunglung']] ).to_s.should == '(&(uid=kunglung))'
	end

	it "parses an AND expression with multiple clauses" do
		Treequel::Filter.new( [:&, [:uid, 'kunglung'], [:name, 'chunger']] ).to_s.
			should == '(&(uid=kunglung)(name=chunger))'
	end

	it "parses a complex nested expression" do
		Treequel::Filter.new(
			[:and,
				[:or,
					[:and, [:chungability,'fantagulous'], [:l, 'the moon']],
					[:chungability, 'gruntworthy']],
				[:not, [:description, 'mediocre']] ]
		).to_s.should == '(&(|(&(chungability=fantagulous)(l=the moon))' +
			'(chungability=gruntworthy))(!(description=mediocre)))'
	end


	describe "components:" do

		before( :each ) do
			@clause1 = stub( "clause1", :to_s => '(clause1)' )
			@clause2 = stub( "clause2", :to_s => '(clause2)' )
		end

		describe Treequel::Filter::AndComponent do
			it "stringifies as its clauses ANDed together" do
				Treequel::Filter::AndComponent.new( @clause1, @clause2 ).to_s.
					should == '&(clause1)(clause2)'
			end

			it "allows a single clause" do
				Treequel::Filter::AndComponent.new( @clause1 ).to_s.
					should == '&(clause1)'
			end
		end

		describe Treequel::Filter::OrComponent do
			it "stringifies as its clauses ORed together" do
				Treequel::Filter::OrComponent.new( @clause1, @clause2 ).to_s.
					should == '|(clause1)(clause2)'
			end

			it "allows a single clause" do
				Treequel::Filter::OrComponent.new( @clause1 ).to_s.
					should == '|(clause1)'
			end
		end

		describe Treequel::Filter::NotComponent do
			it "stringifies as the negation of its clause" do
				Treequel::Filter::NotComponent.new( @clause1 ).to_s.
					should == '!(clause1)'
			end

			it "can't be created with multiple clauses" do
				lambda {
					Treequel::Filter::NotComponent.new( @clause1, @clause2 )
				}.should raise_error( ArgumentError, /2 for 1/i )
			end
		end
	end
end


# vim: set nosta noet ts=4 sw=4:

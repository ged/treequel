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

	require 'treequel/branchset/clauses'
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

describe Treequel::BranchSet, "clauses" do
	include Treequel::SpecHelpers
	
	before( :all ) do
		setup_logging( :fatal )
	end
	
	after( :all ) do
		reset_logging()
	end


	describe Treequel::BranchSet::Clause do
		it "can't be instantiated directly" do
			lambda {
				Treequel::BranchSet::Clause.new
			}.should raise_error( NoMethodError )
		end
		
	end
	
	
	describe Treequel::BranchSet::LiteralClause do
		it "wraps the filterstring in parens"
		
	end
end


# vim: set nosta noet ts=4 sw=4:

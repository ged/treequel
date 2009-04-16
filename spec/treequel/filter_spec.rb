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


	it "knows that it is promiscuous (will match any entry) if its component is promiscuous" do
		Treequel::Filter.new.should be_promiscuous()
	end
	
	it "knows that it isn't promiscuous if its component isn't promiscuous" do
		Treequel::Filter.new( :uid, 'batgirl' ).should_not be_promiscuous()
	end
	

	it "defaults to selecting everything" do
		Treequel::Filter.new.to_s.should == '(objectClass=*)'
	end

	it "can be created from a string literal" do
		Treequel::Filter.new( '(uid=bargrab)' ).to_s.should == '(uid=bargrab)'
	end

	it "wraps string literal instances in parens if it requires them" do
		Treequel::Filter.new( 'uid=bargrab' ).to_s.should == '(uid=bargrab)'
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
		Treequel::Filter.new( [:and, [:uid, 'kunglung'], [:name, 'chunger']] ).to_s.
			should == '(&(uid=kunglung)(name=chunger))'
	end

	it "parses an OR expression with only a single clause" do
		Treequel::Filter.new( [:|, [:uid, 'kunglung']] ).to_s.should == '(|(uid=kunglung))'
	end

	it "parses an OR expression with multiple clauses" do
		Treequel::Filter.new( [:or, [:uid, 'kunglung'], [:name, 'chunger']] ).to_s.
			should == '(|(uid=kunglung)(name=chunger))'
	end
	
	it "parses the hash form of OR expression" do
		Treequel::Filter.new( [:or, {:uid => %w[lar bin fon guh]} ]).to_s.
			should == '(|(uid=lar)(uid=bin)(uid=fon)(uid=guh))'
	end
	

	it "parses a NOT expression with only a single clause" do
		Treequel::Filter.new( [:'!', [:uid, 'kunglung']] ).to_s.should == '(!(uid=kunglung))'
	end

	it "raises an exception with a NOT expression that contains more than one clause" do
		lambda { 		
			Treequel::Filter.new( [:not, [:uid, 'kunglung'], [:name, 'chunger']] )
		 }.should raise_error( ArgumentError )
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


	### Operators
	describe "operator methods" do

		before( :each ) do
			@filter1 = Treequel::Filter.new( :uid, :buckrogers )
			@filter2 = Treequel::Filter.new( :l, :mars )
		end
		
		it "compares as equal with another filter if their components are equal" do
			otherfilter = mock( "other filter" )
			otherfilter.should_receive( :component ).and_return( :componentobj )
			@filter1.component = :componentobj
			
			@filter1.should == otherfilter
		end

		it "creates a new AND filter out of two filters that are added together" do
			result = @filter1 + @filter2
			result.should be_a( Treequel::Filter )
		end
	
		it "creates a new AND filter out of two filters that are bitwise-ANDed together" do
			result = @filter1 & @filter2
			result.should be_a( Treequel::Filter )
		end
	
		it "doesn't include the left operand in an AND filter if it is promiscuous" do
			pfilter = Treequel::Filter.new
			result = pfilter & @filter2

			result.should == @filter2
		end
	
		it "doesn't include the right operand in an AND filter if it is promiscuous" do
			pfilter = Treequel::Filter.new
			result = @filter1 & pfilter

			result.should == @filter1
		end
	
	end

	describe "components:" do

		before( :each ) do
			@clause1 = stub( "clause1", :to_s => '(clause1)' )
			@clause2 = stub( "clause2", :to_s => '(clause2)' )
		end


		describe Treequel::Filter::Component do
			it "is an abstract class" do
				lambda {
					Treequel::Filter::Component.new
				 }.should raise_error( NoMethodError )
			end
			
			it "is non-promiscuous by default" do
				Class.new( Treequel::Filter::Component ).new.should_not be_promiscuous()
			end
			
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

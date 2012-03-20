#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'treequel/filter'


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

	it "escapes filter metacharacters in simple item equal filters" do
		Treequel::Filter.new( :nisNetgroupTriple, '(blarney.acme.org,,)' ).to_s.
			should == '(nisNetgroupTriple=\28blarney.acme.org,,\29)'
	end

	it "parses a String+value hash as a simple item equal filter" do
		Treequel::Filter.new( 'uid' => 'bigthung' ).to_s.should == '(uid=bigthung)'
	end

	it "parses a single-item Symbol+value hash as a simple item equal filter" do
		Treequel::Filter.new({ :uidNumber => 3036 }).to_s.should == '(uidNumber=3036)'
	end

	it "parses a Symbol+value pair in an Array as a simple item equal filter" do
		Treequel::Filter.new( [:uid, 'bigthung'] ).to_s.should == '(uid=bigthung)'
	end

	it "parses a multi-value Hash as an ANDed collection of simple item equals filters" do
		expr = Treequel::Filter.new( :givenName => 'Michael', :sn => 'Granger' )
		gnpat = Regexp.quote( '(givenName=Michael)' )
		snpat = Regexp.quote( '(sn=Granger)' )

		expr.to_s.should =~ /\(&(#{gnpat}#{snpat}|#{snpat}#{gnpat})\)/i
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

	it "parses an OR expression with String literal clauses" do
		Treequel::Filter.new( :or, ['cn~=facet', 'cn=structure', 'cn=envision'] ).to_s.
			should == '(|(cn~=facet)(cn=structure)(cn=envision))'
	end

	it "infers the OR-hash form if the expression is Symbol => Array" do
		Treequel::Filter.new( :uid => %w[lar bin fon guh] ).to_s.
			should == '(|(uid=lar)(uid=bin)(uid=fon)(uid=guh))'
	end

	it "doesn't make an OR-hash if the expression is singular" do
		Treequel::Filter.new( :uid => ['lar'] ).to_s.should == '(uid=lar)'
	end

	it "correctly includes OR subfilters in a Hash if the value is an Array" do
		fstr = Treequel::Filter.new( :objectClass => 'inetOrgPerson', :uid => %w[lar bin fon guh] ).to_s

		fstr.should include('(|(uid=lar)(uid=bin)(uid=fon)(uid=guh))')
		fstr.should include('(objectClass=inetOrgPerson)')
		fstr.should =~ /^\(&/
	end

	it "parses a NOT expression with only a single clause" do
		Treequel::Filter.new( [:'!', [:uid, 'kunglung']] ).to_s.should == '(!(uid=kunglung))'
	end

	it "parses a Range item as a boolean ANDed expression" do
		filter = Treequel::Filter.new( :uid, 200..1000 ).to_s.should == '(&(uid>=200)(uid<=1000))'
	end

	it "parses a exclusive Range correctly" do
		filter = Treequel::Filter.new( :uid, 200...1000 ).to_s.should == '(&(uid>=200)(uid<=999))'
	end

	it "parses a Range item with non-numeric components" do
		filter = Treequel::Filter.new( :lastName => 'Dale'..'Darby' ).to_s.
			should == '(&(lastName>=Dale)(lastName<=Darby))'
	end

	it "raises an exception with a NOT expression that contains more than one clause" do
		expect {
			Treequel::Filter.new( :not, [:uid, 'kunglung'], [:name, 'chunger'] )
		 }.to raise_error( ArgumentError )
	end


	it "parses a Substring item from a filter that includes an asterisk" do
		filter = Treequel::Filter.new( :portrait, "\\ff\\d8\\ff\\e0*" )
		filter.component.class.should == Treequel::Filter::SubstringItemComponent
	end

	it "parses a Present item from a filter that is only an asterisk" do
		filter = Treequel::Filter.new( :disabled, "*" )
		filter.component.class.should == Treequel::Filter::PresentItemComponent
	end

	it "raises an error when an extensible item filter is given" do
		expect {
			Treequel::Filter.new( :'cn:1.2.3.4.5:', 'Fred Flintstone' )
		 }.to raise_error( NotImplementedError, /extensible.*supported/i )
	end


	it "parses a complex nested expression" do
		Treequel::Filter.new(
			[:and,
				[:or,
					[:and, [:chungability,'fantagulous'], [:l, 'the moon']],
					[:chungability, '*grunt*'],
					[:hunker]],
				[:not, [:description, 'mediocre']] ]
		).to_s.should == '(&(|(&(chungability=fantagulous)(l=the moon))' +
			'(chungability=*grunt*)(hunker=*))(!(description=mediocre)))'
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

		it "creates a new OR filter out of two filters that are bitwise-ORed together" do
			result = @filter1 | @filter2
			result.should be_a( Treequel::Filter )
		end

		it "collapses two OR filters into a single OR clause when bitwise-ORed together" do
			orfilter = @filter1 | @filter2
			thirdfilter = Treequel::Filter.new( :l => :saturn )
			result = ( orfilter | thirdfilter )

			result.should be_a( Treequel::Filter )
			result.to_s.should == '(|(uid=buckrogers)(l=mars)(l=saturn))'
		end

	end

	describe "components:" do

		before( :each ) do
			@filter1 = Treequel::Filter.new( '(filter1)' )
			@filter2 = Treequel::Filter.new( '(filter2)' )
		end


		describe Treequel::Filter::FilterList do
			it "stringifies by joining its stringified members" do
				Treequel::Filter::FilterList.new( @filter1, @filter2 ).to_s.
					should == '(filter1)(filter2)'
			end

			it "supports appending via the << operator" do
				list = Treequel::Filter::FilterList.new( @filter1 )
				( list << @filter2 ).should == list
				list.to_s.should == '(filter1)(filter2)'
			end
		end

		describe Treequel::Filter::Component do
			it "is an abstract class" do
				expect {
					Treequel::Filter::Component.new
				 }.to raise_error( NoMethodError )
			end

			it "is non-promiscuous by default" do
				Class.new( Treequel::Filter::Component ).new.should_not be_promiscuous()
			end

		end


		describe Treequel::Filter::SimpleItemComponent do
			before( :each ) do
				@component = Treequel::Filter::SimpleItemComponent.new( :uid, 'schlange' )
			end

			it "can parse a component object from a string literal" do
				comp = Treequel::Filter::SimpleItemComponent.parse_from_string( 'description=screamer' )
				comp.filtertype.should    == :equal
				comp.filtertype_op.should == '='
				comp.attribute.should     == 'description'
				comp.value.should         == 'screamer'
			end

			it "raises an ExpressionError if it can't parse a string literal" do
				expect { Treequel::Filter::SimpleItemComponent.parse_from_string( 'whatev!' ) }.
					to raise_error( Treequel::ExpressionError, /unable to parse/i )
			end

			it "uses the 'equal' operator if none is specified" do
				@component.filtertype.should == :equal
			end

			it "knows what the appropriate operator is for its filtertype" do
				@component.filtertype_op.should == '='
			end

			it "knows what the appropriate operator is for its filtertype even if it's set to a string" do
				@component.filtertype = 'greater'
				@component.filtertype_op.should == '>='
			end

			it "stringifies as <attribute><operator><value>" do
				@component.to_s.should == 'uid=schlange'
			end

			it "uses the '~=' operator if its filtertype is 'approx'" do
				@component.filtertype = :approx
				@component.filtertype_op.should == '~='
			end

			it "uses the '>=' operator if its filtertype is 'greater'" do
				@component.filtertype = :greater
				@component.filtertype_op.should == '>='
			end

			it "uses the '<=' operator if its filtertype is 'less'" do
				@component.filtertype = :less
				@component.filtertype_op.should == '<='
			end

			it "raises an error if it's created with an unknown filtertype" do
				expect { 
					Treequel::Filter::SimpleItemComponent.new( :uid, 'schlange', :fork )
				}.to raise_error( Treequel::ExpressionError, /invalid/i )

			end

		end


		describe Treequel::Filter::SubstringItemComponent do

			before( :each ) do
				@component = Treequel::Filter::SubstringItemComponent.new( :description, '*basecamp*' )
			end


			it "can parse a component object from a string literal" do
				comp = Treequel::Filter::SubstringItemComponent.parse_from_string( 'description=*basecamp*' )
				comp.attribute.should == 'description'
				comp.options.should   == ''
				comp.pattern.should   == '*basecamp*'
			end

			it "can parse a component object from a string literal with attribute options" do
				jpeg_portraits = Treequel::Filter::SubstringItemComponent.
					parse_from_string( "portrait;binary=\\xff\\xd8\\xff\\xe0*" )
				jpeg_portraits.attribute.should == 'portrait'
				jpeg_portraits.options.should   == ';binary'
				jpeg_portraits.pattern.should   == "\\xff\\xd8\\xff\\xe0*"
			end

			it "raises an ExpressionError if it can't parse a string literal" do
				expect { Treequel::Filter::SubstringItemComponent.parse_from_string( 'whatev>=1' ) }.
					to raise_error( Treequel::ExpressionError, /unable to parse/i )
			end

		end


		describe Treequel::Filter::AndComponent do
			it "stringifies as its filters ANDed together" do
				Treequel::Filter::AndComponent.new( @filter1, @filter2 ).to_s.
					should == '&(filter1)(filter2)'
			end

			it "allows a single filter" do
				Treequel::Filter::AndComponent.new( @filter1 ).to_s.
					should == '&(filter1)'
			end
		end

		describe Treequel::Filter::OrComponent do
			it "stringifies as its filters ORed together" do
				Treequel::Filter::OrComponent.new( @filter1, @filter2 ).to_s.
					should == '|(filter1)(filter2)'
			end

			it "allows a single filter" do
				Treequel::Filter::OrComponent.new( @filter1 ).to_s.
					should == '|(filter1)'
			end

			it "allows futher alternations to be added to it" do
				filter = Treequel::Filter::OrComponent.new( @filter1 )
				filter.add_alternation( @filter2 )
				filter.to_s.should == '|(filter1)(filter2)'
			end
		end

		describe Treequel::Filter::NotComponent do
			it "stringifies as the negation of its filter" do
				Treequel::Filter::NotComponent.new( @filter1 ).to_s.
					should == '!(filter1)'
			end

			it "can't be created with multiple filters" do
				expect {
					Treequel::Filter::NotComponent.new( @filter1, @filter2 )
				}.to raise_error( ArgumentError, /2 for 1/i )
			end
		end
	end

	describe "support for Sequel expressions", :sequel do

		it "supports the boolean expression syntax", :ruby_18 do
			filter = Treequel::Filter.new( :uid >= 2000 )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(uid>=2000)'
		end

		it "supports Sequel expressions in ANDed subexpressions", :ruby_18 do
			filter = Treequel::Filter.new( :and, [:uid >= 1024], [:uid <= 65535] )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(&(uid>=1024)(uid<=65535))'
		end

		it "advises user to use '>=' instead of '>' in expressions", :ruby_18 do
			expect {
				Treequel::Filter.new( :uid > 1024 )
			}.to raise_error( Treequel::ExpressionError, /greater-than-or-equal/i )
		end

		it "advises user to use '<=' instead of '<' in expressions", :ruby_18 do
			expect {
				Treequel::Filter.new( :activated < Time.now )
			}.to raise_error( Treequel::ExpressionError, /less-than-or-equal/i )
		end

		it "supports the 'LIKE' expression syntax with a single string argument" do
			filter = Treequel::Filter.new( :cn.like('mar*n') )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(cn=mar*n)'
		end

		it "treats a LIKE expression with no asterisks as an 'approx' filter" do
			filter = Treequel::Filter.new( :cn.like('maylin') )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(cn~=maylin)'
		end

		it "supports the 'LIKE' expression syntax with multiple string arguments" do
			filter = Treequel::Filter.new( :cn.like('may*', 'mah*') )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(|(cn=may*)(cn=mah*))'
		end

		it "raises an exception when given a 'LIKE' expression with a regex argument" do
			expect {
				Treequel::Filter.new( :cn.like(/^ma.*/) )
			}.to raise_error( Treequel::ExpressionError, /regex/i )
		end

		it "raises an exception when given a 'LIKE' expression with a regex argument with flags" do
			expect {
				Treequel::Filter.new( :cn.like(/^ma.*/i) )
			}.to raise_error( Treequel::ExpressionError, /regex/i )
		end

		it "raises an exception when given a 'LIKE' expression with a mix of regex and string " +
		   "arguments" do
			expect {
				Treequel::Filter.new( :cn.like('maylin', /^mi.*/i) )
			}.to raise_error( Treequel::ExpressionError, /regex/i )
		end

		it "supports negation of a 'exists' expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~:cn )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(!(cn=*))'
		end

		it "supports negation of a simple equality expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~{ :l => 'anoos' } )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(!(l=anoos))'
		end

		it "supports negation of an approximate-match expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~:cn.like('maylin') )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(!(cn~=maylin))'
		end

		it "supports negation of a matching expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~:cn.like('may*i*') )
			filter.should be_a( Treequel::Filter )
			filter.to_s.should == '(!(cn=may*i*))'
		end
	end
end


# vim: set nosta noet ts=4 sw=4:

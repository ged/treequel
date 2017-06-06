#!/usr/bin/env ruby

require_relative '../spec_helpers'


require 'treequel/filter'


include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Filter do
	include Treequel::SpecHelpers


	it "knows that it is promiscuous (will match any entry) if its component is promiscuous" do
		expect( Treequel::Filter.new ).to be_promiscuous()
	end

	it "knows that it isn't promiscuous if its component isn't promiscuous" do
		expect( Treequel::Filter.new( :uid, 'batgirl' ) ).to_not be_promiscuous()
	end


	it "defaults to selecting everything" do
		expect( Treequel::Filter.new.to_s ).to eq( '(objectClass=*)' )
	end

	it "can be created from a string literal" do
		expect( Treequel::Filter.new( '(uid=bargrab)' ).to_s ).to eq( '(uid=bargrab)' )
	end

	it "wraps string literal instances in parens if it requires them" do
		expect( Treequel::Filter.new( 'uid=bargrab' ).to_s ).to eq( '(uid=bargrab)' )
	end

	it "parses a single Symbol argument as a presence filter" do
		expect( Treequel::Filter.new( :uid ).to_s ).to eq( '(uid=*)' )
	end

	it "parses a single-element Array with a Symbol as a presence filter" do
		expect( Treequel::Filter.new( [:uid] ).to_s ).to eq( '(uid=*)' )
	end

	it "parses a Symbol+value pair as a simple item equal filter" do
		expect( Treequel::Filter.new( :uid, 'bigthung' ).to_s ).to eq( '(uid=bigthung)' )
	end

	it "escapes filter metacharacters in simple item equal filters" do
		expect( Treequel::Filter.new( :nisNetgroupTriple, '(blarney.acme.org,,)' ).to_s ).
			to eq( '(nisNetgroupTriple=\28blarney.acme.org,,\29)' )
	end

	it "parses a String+value hash as a simple item equal filter" do
		expect( Treequel::Filter.new( 'uid' => 'bigthung' ).to_s ).to eq( '(uid=bigthung)' )
	end

	it "parses a single-item Symbol+value hash as a simple item equal filter" do
		expect( Treequel::Filter.new({ :uidNumber => 3036 }).to_s ).to eq( '(uidNumber=3036)' )
	end

	it "parses a Symbol+value pair in an Array as a simple item equal filter" do
		expect( Treequel::Filter.new( [:uid, 'bigthung'] ).to_s ).to eq( '(uid=bigthung)' )
	end

	it "parses a multi-value Hash as an ANDed collection of simple item equals filters" do
		expr = Treequel::Filter.new( :givenName => 'Michael', :sn => 'Granger' )
		gnpat = Regexp.quote( '(givenName=Michael)' )
		snpat = Regexp.quote( '(sn=Granger)' )

		expect( expr.to_s ).to match( /\(&(#{gnpat}#{snpat}|#{snpat}#{gnpat})\)/i )
	end

	it "parses an AND expression with only a single clause" do
		expect( Treequel::Filter.new( [:&, [:uid, 'kunglung']] ).to_s ).to eq( '(&(uid=kunglung))' )
	end

	it "parses an AND expression with multiple clauses" do
		expect( Treequel::Filter.new( [:and, [:uid, 'kunglung'], [:name, 'chunger']] ).to_s ).
			to eq( '(&(uid=kunglung)(name=chunger))' )
	end

	it "parses an OR expression with only a single clause" do
		expect( Treequel::Filter.new( [:|, [:uid, 'kunglung']] ).to_s ).to eq( '(|(uid=kunglung))' )
	end

	it "parses an OR expression with multiple clauses" do
		expect( Treequel::Filter.new( [:or, [:uid, 'kunglung'], [:name, 'chunger']] ).to_s ).
			to eq( '(|(uid=kunglung)(name=chunger))' )
	end

	it "parses an OR expression with String literal clauses" do
		expect( Treequel::Filter.new( :or, ['cn~=facet', 'cn=structure', 'cn=envision'] ).to_s ).
			to eq( '(|(cn~=facet)(cn=structure)(cn=envision))' )
	end

	it "infers the OR-hash form if the expression is Symbol => Array" do
		expect( Treequel::Filter.new( :uid => %w[lar bin fon guh] ).to_s ).
			to eq( '(|(uid=lar)(uid=bin)(uid=fon)(uid=guh))' )
	end

	it "doesn't make an OR-hash if the expression is singular" do
		expect( Treequel::Filter.new( :uid => ['lar'] ).to_s ).to eq( '(uid=lar)' )
	end

	it "correctly includes OR subfilters in a Hash if the value is an Array" do
		fstr = Treequel::Filter.new( :objectClass => 'inetOrgPerson', :uid => %w[lar bin fon guh] ).to_s

		expect( fstr ).to include('(|(uid=lar)(uid=bin)(uid=fon)(uid=guh))')
		expect( fstr ).to include('(objectClass=inetOrgPerson)')
		expect( fstr ).to match( /^\(&/ )
	end

	it "parses a NOT expression with only a single clause" do
		expect( Treequel::Filter.new( [:'!', [:uid, 'kunglung']] ).to_s ).to eq( '(!(uid=kunglung))' )
	end

	it "parses a Range item as a boolean ANDed expression" do
		expect( filter = Treequel::Filter.new( :uid, 200..1000 ).to_s ).to eq( '(&(uid>=200)(uid<=1000))' )
	end

	it "parses a exclusive Range correctly" do
		expect( filter = Treequel::Filter.new( :uid, 200...1000 ).to_s ).to eq( '(&(uid>=200)(uid<=999))' )
	end

	it "parses a Range item with non-numeric components" do
		expect( filter = Treequel::Filter.new( :lastName => 'Dale'..'Darby' ).to_s ).
			to eq( '(&(lastName>=Dale)(lastName<=Darby))' )
	end

	it "raises an exception with a NOT expression that contains more than one clause" do
		expect {
			Treequel::Filter.new( :not, [:uid, 'kunglung'], [:name, 'chunger'] )
		 }.to raise_error( ArgumentError )
	end


	it "parses a Substring item from a filter that includes an asterisk" do
		filter = Treequel::Filter.new( :portrait, "\\ff\\d8\\ff\\e0*" )
		expect( filter.component.class ).to eq( Treequel::Filter::SubstringItemComponent )
	end

	it "parses a Present item from a filter that is only an asterisk" do
		filter = Treequel::Filter.new( :disabled, "*" )
		expect( filter.component.class ).to eq( Treequel::Filter::PresentItemComponent )
	end

	it "raises an error when an extensible item filter is given" do
		expect {
			Treequel::Filter.new( :'cn:1.2.3.4.5:', 'Fred Flintstone' )
		 }.to raise_error( NotImplementedError, /extensible.*supported/i )
	end


	it "parses a complex nested expression" do
		result = Treequel::Filter.new(
			[:and,
				[:or,
					[:and, [:chungability,'fantagulous'], [:l, 'the moon']],
					[:chungability, '*grunt*'],
					[:hunker]],
				[:not, [:description, 'mediocre']] ]
			)
		expect( result.to_s ).to eq(
			'(&(|(&(chungability=fantagulous)(l=the moon))' +
			'(chungability=*grunt*)(hunker=*))(!(description=mediocre)))'
		)
	end


	### Operators
	describe "operator methods" do

		before( :each ) do
			@filter1 = Treequel::Filter.new( :uid, :buckrogers )
			@filter2 = Treequel::Filter.new( :l, :mars )
		end

		it "compares as equal with another filter if their components are equal" do
			otherfilter = double( "other filter" )
			expect( otherfilter ).to receive( :component ).and_return( :componentobj )
			@filter1.component = :componentobj

			expect( @filter1 ).to eq( otherfilter )
		end

		it "creates a new AND filter out of two filters that are added together" do
			result = @filter1 + @filter2
			expect( result ).to be_a( Treequel::Filter )
		end

		it "creates a new AND filter out of two filters that are bitwise-ANDed together" do
			result = @filter1 & @filter2
			expect( result ).to be_a( Treequel::Filter )
		end

		it "doesn't include the left operand in an AND filter if it is promiscuous" do
			pfilter = Treequel::Filter.new
			result = pfilter & @filter2

			expect( result ).to eq( @filter2 )
		end

		it "doesn't include the right operand in an AND filter if it is promiscuous" do
			pfilter = Treequel::Filter.new
			result = @filter1 & pfilter

			expect( result ).to eq( @filter1 )
		end

		it "creates a new OR filter out of two filters that are bitwise-ORed together" do
			result = @filter1 | @filter2
			expect( result ).to be_a( Treequel::Filter )
		end

		it "collapses two OR filters into a single OR clause when bitwise-ORed together" do
			orfilter = @filter1 | @filter2
			thirdfilter = Treequel::Filter.new( :l => :saturn )
			result = ( orfilter | thirdfilter )

			expect( result ).to be_a( Treequel::Filter )
			expect( result.to_s ).to eq( '(|(uid=buckrogers)(l=mars)(l=saturn))' )
		end

	end

	describe "components:" do

		before( :each ) do
			@filter1 = Treequel::Filter.new( '(filter1)' )
			@filter2 = Treequel::Filter.new( '(filter2)' )
		end


		describe Treequel::Filter::FilterList do
			it "stringifies by joining its stringified members" do
				expect( Treequel::Filter::FilterList.new( @filter1, @filter2 ).to_s ).
					to eq( '(filter1)(filter2)' )
			end

			it "supports appending via the << operator" do
				list = Treequel::Filter::FilterList.new( @filter1 )
				expect( ( list << @filter2 ) ).to eq( list )
				expect( list.to_s ).to eq( '(filter1)(filter2)' )
			end
		end

		describe Treequel::Filter::Component do
			it "is an abstract class" do
				expect {
					Treequel::Filter::Component.new
				 }.to raise_error( NoMethodError )
			end

			it "is non-promiscuous by default" do
				expect( Class.new( Treequel::Filter::Component ).new ).to_not be_promiscuous()
			end

		end


		describe Treequel::Filter::SimpleItemComponent do
			before( :each ) do
				@component = Treequel::Filter::SimpleItemComponent.new( :uid, 'schlange' )
			end

			it "can parse a component object from a string literal" do
				comp = Treequel::Filter::SimpleItemComponent.parse_from_string( 'description=screamer' )
				expect( comp.filtertype ).to eq( :equal )
				expect( comp.filtertype_op ).to eq( '=' )
				expect( comp.attribute ).to eq( 'description' )
				expect( comp.value ).to eq( 'screamer' )
			end

			it "raises an ExpressionError if it can't parse a string literal" do
				expect { Treequel::Filter::SimpleItemComponent.parse_from_string( 'whatev!' ) }.
					to raise_error( Treequel::ExpressionError, /unable to parse/i )
			end

			it "uses the 'equal' operator if none is specified" do
				expect( @component.filtertype ).to eq( :equal )
			end

			it "knows what the appropriate operator is for its filtertype" do
				expect( @component.filtertype_op ).to eq( '=' )
			end

			it "knows what the appropriate operator is for its filtertype even if it's set to a string" do
				@component.filtertype = 'greater'
				expect( @component.filtertype_op ).to eq( '>=' )
			end

			it "stringifies as <attribute><operator><value>" do
				expect( @component.to_s ).to eq( 'uid=schlange' )
			end

			it "uses the '~=' operator if its filtertype is 'approx'" do
				@component.filtertype = :approx
				expect( @component.filtertype_op ).to eq( '~=' )
			end

			it "uses the '>=' operator if its filtertype is 'greater'" do
				@component.filtertype = :greater
				expect( @component.filtertype_op ).to eq( '>=' )
			end

			it "uses the '<=' operator if its filtertype is 'less'" do
				@component.filtertype = :less
				expect( @component.filtertype_op ).to eq( '<=' )
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
				expect( comp.attribute ).to eq( 'description' )
				expect( comp.options ).to eq( '' )
				expect( comp.pattern ).to eq( '*basecamp*' )
			end

			it "can parse a component object from a string literal with attribute options" do
				jpeg_portraits = Treequel::Filter::SubstringItemComponent.
					parse_from_string( "portrait;binary=\\xff\\xd8\\xff\\xe0*" )
				expect( jpeg_portraits.attribute ).to eq( 'portrait' )
				expect( jpeg_portraits.options ).to eq( ';binary' )
				expect( jpeg_portraits.pattern ).to eq( "\\xff\\xd8\\xff\\xe0*" )
			end

			it "raises an ExpressionError if it can't parse a string literal" do
				expect { Treequel::Filter::SubstringItemComponent.parse_from_string( 'whatev>=1' ) }.
					to raise_error( Treequel::ExpressionError, /unable to parse/i )
			end

		end


		describe Treequel::Filter::AndComponent do
			it "stringifies as its filters ANDed together" do
				expect( Treequel::Filter::AndComponent.new( @filter1, @filter2 ).to_s ).
					to eq( '&(filter1)(filter2)' )
			end

			it "allows a single filter" do
				expect( Treequel::Filter::AndComponent.new( @filter1 ).to_s ).to eq( '&(filter1)' )
			end
		end

		describe Treequel::Filter::OrComponent do
			it "stringifies as its filters ORed together" do
				expect( Treequel::Filter::OrComponent.new( @filter1, @filter2 ).to_s ).
					to eq( '|(filter1)(filter2)' )
			end

			it "allows a single filter" do
				expect( Treequel::Filter::OrComponent.new( @filter1 ).to_s ).to eq( '|(filter1)' )
			end

			it "allows futher alternations to be added to it" do
				filter = Treequel::Filter::OrComponent.new( @filter1 )
				filter.add_alternation( @filter2 )
				expect( filter.to_s ).to eq( '|(filter1)(filter2)' )
			end
		end

		describe Treequel::Filter::NotComponent do
			it "stringifies as the negation of its filter" do
				expect( Treequel::Filter::NotComponent.new( @filter1 ).to_s ).to eq( '!(filter1)' )
			end

			it "can't be created with multiple filters" do
				expect {
					Treequel::Filter::NotComponent.new( @filter1, @filter2 )
				}.to raise_error( ArgumentError, /given 2, expected 1/i )
			end
		end
	end

	describe "support for Sequel expressions", :sequel do

		it "supports the boolean expression syntax", :ruby_18 do
			pending "Figuring out how to handle the old Sequel Symbol-operator syntax"
			filter = Treequel::Filter.new( :uid >= 2000 )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(uid>=2000)' )
		end

		it "supports Sequel expressions in ANDed subexpressions", :ruby_18 do
			pending "Figuring out how to handle the old Sequel Symbol-operator syntax"
			filter = Treequel::Filter.new( :and, [:uid >= 1024], [:uid <= 65535] )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(&(uid>=1024)(uid<=65535))' )
		end

		it "advises user to use '>=' instead of '>' in expressions", :ruby_18 do
			pending "Figuring out how to handle the old Sequel Symbol-operator syntax"
			expect {
				Treequel::Filter.new( :uid > 1024 )
			}.to raise_error( Treequel::ExpressionError, /greater-than-or-equal/i )
		end

		it "advises user to use '<=' instead of '<' in expressions", :ruby_18 do
			pending "Figuring out how to handle the old Sequel Symbol-operator syntax"
			expect {
				Treequel::Filter.new( :activated < Time.now )
			}.to raise_error( Treequel::ExpressionError, /less-than-or-equal/i )
		end

		it "supports the 'LIKE' expression syntax with a single string argument" do
			filter = Treequel::Filter.new( :cn.like('mar*n') )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(cn=mar*n)' )
		end

		it "treats a LIKE expression with no asterisks as an 'approx' filter" do
			filter = Treequel::Filter.new( :cn.like('maylin') )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(cn~=maylin)' )
		end

		it "supports the 'LIKE' expression syntax with multiple string arguments" do
			filter = Treequel::Filter.new( :cn.like('may*', 'mah*') )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(|(cn=may*)(cn=mah*))' )
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
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(!(cn=*))' )
		end

		it "supports negation of a simple equality expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~{ :l => 'anoos' } )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(!(l=anoos))' )
		end

		it "supports negation of an approximate-match expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~:cn.like('maylin') )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(!(cn~=maylin))' )
		end

		it "supports negation of a matching expression via the Sequel ~ syntax" do
			filter = Treequel::Filter.new( ~:cn.like('may*i*') )
			expect( filter ).to be_a( Treequel::Filter )
			expect( filter.to_s ).to eq( '(!(cn=may*i*))' )
		end
	end
end


# vim: set nosta noet ts=4 sw=4:

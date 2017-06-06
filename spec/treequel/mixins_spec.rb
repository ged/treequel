#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"
	extdir = basedir + "ext"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
	$LOAD_PATH.unshift( extdir ) unless $LOAD_PATH.include?( extdir )
}



require 'treequel'
require 'treequel/mixins'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel, "mixin" do

	describe Treequel::Loggable, "mixed into a class" do
		before(:each) do
			@log_output = []
			Treequel.logger.output_to( @log_output )
			Treequel.logger.level = :debug

			@test_class = Class.new do
				include Treequel::Loggable

				def log_test_message( level, msg )
					self.log.send( level, msg )
				end
			end
			@obj = @test_class.new
		end


		it "is able to output to the log via its #log method" do
			@obj.log_test_message( :debug, "debugging message" )
			expect( @log_output.last ).to match( /debugging message/i )
		end
	end

	describe Treequel::HashUtilities do
		it "includes a function for stringifying Hash keys" do
			testhash = {
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			}

			result = Treequel::HashUtilities.stringify_keys( testhash )

			expect( result ).to be_an_instance_of( Hash )
			expect( result ).to_not be_equal( testhash )
			expect( result ).to eq(
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			)
		end


		it "includes a function for symbolifying Hash keys" do
			testhash = {
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			}

			result = Treequel::HashUtilities.symbolify_keys( testhash )

			expect( result ).to be_an_instance_of( Hash )
			expect( result ).to_not be_equal( testhash )
			expect( result ).to eq(
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			)
		end

		it "includes a function that can be used as the key-collision callback for " +
		   "Hash#merge that does recursive merging" do
			hash1 = {
				:foo => 1,
				:bar => [:one],
				:baz => {
					:glom => [:chunker]
				}
			}
			hash2 = {
				:klong => 88.8,
				:bar => [:locke],
				:baz => {
					:trim => :liquor,
					:glom => [:plunker]
				}
			}

			expect( hash1.merge( hash2, &Treequel::HashUtilities.method(:merge_recursively) ) ).to eq(
				:foo => 1,
				:bar => [:one, :locke],
				:baz => {
					:glom => [:chunker, :plunker],
					:trim => :liquor,
				},
				:klong => 88.8
			)
		end

	end

	describe Treequel::ArrayUtilities do

		it "includes a function for stringifying Array elements" do
			testarray = [:a, :b, :c, [:d, :e, [:f, :g]]]

			result = Treequel::ArrayUtilities.stringify_array( testarray )

			expect( result ).to be_an_instance_of( Array )
			expect( result ).to_not be_equal( testarray )
			expect( result ).to eq( ['a', 'b', 'c', ['d', 'e', ['f', 'g']]] )
		end


		it "includes a function for symbolifying Array elements" do
			testarray = ['a', 'b', 'c', ['d', 'e', ['f', 'g']]]

			result = Treequel::ArrayUtilities.symbolify_array( testarray )

			expect( result ).to be_an_instance_of( Array )
			expect( result ).to_not be_equal( testarray )
			expect( result ).to eq( [:a, :b, :c, [:d, :e, [:f, :g]]] )
		end
	end

	describe Treequel::AttributeDeclarations do

		describe "predicate attribute declaration" do
			before( :all ) do
				@testclass = Class.new do
					extend Treequel::AttributeDeclarations

					def initialize( val )
						@testable = val
					end

					predicate_attr :testable
				end
			end

			it "creates a plain predicate method" do
				expect( @testclass.new( true ) ).to be_testable()
				expect( @testclass.new( false ) ).to_not be_testable()
				expect( @testclass.new( 1 ) ).to be_testable()
				expect( @testclass.new( :something_else ) ).to be_testable()
			end

			it "creates a mutator" do
				obj = @testclass.new( true )
				obj.testable = false
				expect( obj ).to_not be_testable()
				obj.testable = true
				expect( obj ).to be_testable()
			end
		end
	end

	describe Treequel::Delegation do

		describe "method delegation" do
			before( :all ) do
				@testclass = Class.new do
					extend Treequel::Delegation

					def initialize( obj )
						@obj = obj
					end

					def_method_delegators :demand_loaded_object, :delegated_method
					def_method_delegators :nonexistant_method, :erroring_delegated_method

					def demand_loaded_object
						return @obj
					end
				end
			end

			before( :each ) do
				@subobj = double( "delegate" )
				@obj = @testclass.new( @subobj )
			end


			it "can be used to set up delegation through a method" do
				expect( @subobj ).to receive( :delegated_method )
				@obj.delegated_method
			end

			it "passes any arguments through to the delegate object's method" do
				expect( @subobj ).to receive( :delegated_method ).with( :arg1, :arg2 )
				@obj.delegated_method( :arg1, :arg2 )
			end

			it "allows delegation to the delegate object's method with a block" do
				expect( @subobj ).to receive( :delegated_method ).with( :arg1 ).
					and_yield( :the_block_argument )
				blockarg = nil
				@obj.delegated_method( :arg1 ) {|arg| blockarg = arg }
				expect( blockarg ).to eq( :the_block_argument )
			end

			it "reports errors from its caller's perspective", :ruby_18 do
				begin
					@obj.erroring_delegated_method
				rescue NoMethodError => err
					expect( err.message ).to match( /nonexistant_method/ )
					expect( err.backtrace.first ).to match( /#{__FILE__}/ )
				rescue ::Exception => err
					fail "Expected a NoMethodError, but got a %p (%s)" % [ err.class, err.message ]
				else
					fail "Expected a NoMethodError, but no exception was raised."
				end
			end

		end

		describe "instance variable delegation (ala Forwardable)" do
			before( :all ) do
				@testclass = Class.new do
					extend Treequel::Delegation

					def initialize( obj )
						@obj = obj
					end

					def_ivar_delegators :@obj, :delegated_method
					def_ivar_delegators :@glong, :erroring_delegated_method

				end
			end

			before( :each ) do
				@subobj = double( "delegate" )
				@obj = @testclass.new( @subobj )
			end


			it "can be used to set up delegation through a method" do
				expect( @subobj ).to receive( :delegated_method )
				@obj.delegated_method
			end

			it "passes any arguments through to the delegate's method" do
				expect( @subobj ).to receive( :delegated_method ).with( :arg1, :arg2 )
				@obj.delegated_method( :arg1, :arg2 )
			end

			it "allows delegation to the delegate's method with a block" do
				expect( @subobj ).to receive( :delegated_method ).with( :arg1 ).
					and_yield( :the_block_argument )
				blockarg = nil
				@obj.delegated_method( :arg1 ) {|arg| blockarg = arg }
				expect( blockarg ).to eq( :the_block_argument )
			end

			it "reports errors from its caller's perspective", :ruby_18 do
				begin
					@obj.erroring_delegated_method
				rescue NoMethodError => err
					expect( err.message ).to match( /`erroring_delegated_method' for nil/ )
					expect( err.backtrace.first ).to match( /#{__FILE__}/ )
				rescue ::Exception => err
					fail "Expected a NoMethodError, but got a %p (%s)" % [ err.class, err.message ]
				else
					fail "Expected a NoMethodError, but no exception was raised."
				end
			end

		end

	end

	describe Treequel::Normalization do

		describe "key normalization" do
			it "downcases" do
				expect( Treequel::Normalization.normalize_key( :logonTime ) ).to eq( :logontime )
			end

			it "symbolifies" do
				expect( Treequel::Normalization.normalize_key( 'cn' ) ).to eq( :cn )
			end

			it "strips invalid characters" do
				expect( Treequel::Normalization.normalize_key( 'given name' ) ).to eq( :givenname )
			end

			it "converts hyphens to underscores" do
				expect( Treequel::Normalization.normalize_key( 'apple-nickname' ) ).to eq( :apple_nickname )
			end
		end

		describe "hash normalization" do
			it "applies key-normalization to the keys of a hash" do
				hash = {
					:logonTime       => 'a logon time',
					'cn'             => 'a common name',
					'given name'     => 'a given name',
					'apple-nickname' => 'a nickname',
				}

				expect( Treequel::Normalization.normalize_hash( hash ) ).to eq(
					:logontime      => 'a logon time',
					:cn             => 'a common name',
					:givenname      => 'a given name',
					:apple_nickname => 'a nickname',
				)
			end
		end
	end

end

# vim: set nosta noet ts=4 sw=4:

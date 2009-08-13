#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"
	extdir = basedir + "ext"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
	$LOAD_PATH.unshift( extdir ) unless $LOAD_PATH.include?( extdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel'
	require 'treequel/mixins'
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

describe Treequel, "mixin" do
	include Treequel::SpecHelpers

	describe Treequel::Loggable, "mixed into a class" do
		before(:each) do
			@logfile = StringIO.new('')
			Treequel.logger = Logger.new( @logfile )

			@test_class = Class.new do
				include Treequel::Loggable

				def log_test_message( level, msg )
					self.log.send( level, msg )
				end

				def logdebug_test_message( msg )
					self.log_debug.debug( msg )
				end
			end
			@obj = @test_class.new
		end


		it "is able to output to the log via its #log method" do
			@obj.log_test_message( :debug, "debugging message" )
			@logfile.rewind
			@logfile.read.should =~ /debugging message/
		end

		it "is able to output to the log via its #log_debug method" do
			@obj.logdebug_test_message( "sexydrownwatch" )
			@logfile.rewind
			@logfile.read.should =~ /sexydrownwatch/
		end
	end

	#################################################################
	###	E X A M P L E S
	#################################################################

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

			result.should be_an_instance_of( Hash )
			result.should_not be_equal( testhash )
			result.should == {
				'foo' => 1,
				'bar' => {
					'klang' => 'klong',
					'barang' => { 'kerklang' => 'dumdumdum' },
				}
			}
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

			result.should be_an_instance_of( Hash )
			result.should_not be_equal( testhash )
			result.should == {
				:foo => 1,
				:bar => {
					:klang => 'klong',
					:barang => { :kerklang => 'dumdumdum' },
				}
			}
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

			hash1.merge( hash2, &Treequel::HashUtilities.method(:merge_recursively) ).should == {
				:foo => 1,
				:bar => [:one, :locke],
				:baz => {
					:glom => [:chunker, :plunker],
					:trim => :liquor,
				},
				:klong => 88.8,
			}
		end

	end

	describe Treequel::ArrayUtilities do
		it "includes a function for stringifying Array elements" do
			testarray = [:a, :b, :c, [:d, :e, [:f, :g]]]

			result = Treequel::ArrayUtilities.stringify_array( testarray )

			result.should be_an_instance_of( Array )
			result.should_not be_equal( testarray )
			result.should == ['a', 'b', 'c', ['d', 'e', ['f', 'g']]]
		end


		it "includes a function for symbolifying Array elements" do
			testarray = ['a', 'b', 'c', ['d', 'e', ['f', 'g']]]

			result = Treequel::ArrayUtilities.symbolify_array( testarray )

			result.should be_an_instance_of( Array )
			result.should_not be_equal( testarray )
			result.should == [:a, :b, :c, [:d, :e, [:f, :g]]]
		end
	end


	describe Treequel::AttributeDeclarations do
		before( :all ) do
			setup_logging( :debug )
		end
		after( :all ) do
			reset_logging()
		end

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
				@testclass.new( true ).should be_testable()
				@testclass.new( false ).should_not be_testable()
				@testclass.new( 1 ).should be_testable()
				@testclass.new( :something_else ).should be_testable()
			end

			it "creates a mutator" do
				obj = @testclass.new( true )
				obj.testable = false
				obj.should_not be_testable()
				obj.testable = true
				obj.should be_testable()
			end
		end
	end

	describe Treequel::Delegation do

		before( :all ) do
			setup_logging( :debug )
		end
		after( :all ) do
			reset_logging()
		end

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
				@subobj = mock( "delegate" )
				@obj = @testclass.new( @subobj )
			end


			it "can be used to set up delegation through a method" do
				@subobj.should_receive( :delegated_method )
				@obj.delegated_method
			end

			it "passes any arguments through to the delegate object's method" do
				@subobj.should_receive( :delegated_method ).with( :arg1, :arg2 )
				@obj.delegated_method( :arg1, :arg2 )
			end

			it "reports errors from its caller's perspective" do
				pending "doesn't work under 1.9, but may not be necessary" if
					vvec(RUBY_VERSION) > vvec('1.8.7')

				begin
					@obj.erroring_delegated_method
				rescue NoMethodError => err
					err.message.should =~ /nonexistant_method/
					err.backtrace.first.should =~ /#{__FILE__}/
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
				@subobj = mock( "delegate" )
				@obj = @testclass.new( @subobj )
			end


			it "can be used to set up delegation through a method" do
				@subobj.should_receive( :delegated_method )
				@obj.delegated_method
			end

			it "passes any arguments through to the delegate's method" do
				@subobj.should_receive( :delegated_method ).with( :arg1, :arg2 )
				@obj.delegated_method( :arg1, :arg2 )
			end

			it "reports errors from its caller's perspective" do
				pending "doesn't work under 1.9, but may not be necessary" if
					vvec(RUBY_VERSION) > vvec('1.8.7')

				begin
					@obj.erroring_delegated_method
				rescue NoMethodError => err
					err.message.should =~ /`erroring_delegated_method' for nil/
					err.backtrace.first.should =~ /#{__FILE__}/
				rescue ::Exception => err
					fail "Expected a NoMethodError, but got a %p (%s)" % [ err.class, err.message ]
				else
					fail "Expected a NoMethodError, but no exception was raised."
				end
			end

		end

	end

end

# vim: set nosta noet ts=4 sw=4:

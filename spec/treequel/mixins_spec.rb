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
# include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel, "mixin" do

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

end

# vim: set nosta noet ts=4 sw=4:

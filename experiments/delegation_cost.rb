#!/usr/bin/env ruby

# An experiment to examine the cost of various means of creating delegators

require 'forwardable'
require 'pp'
require 'pathname'
require 'benchmark'

require Pathname( __FILE__ ).dirname + 'utils.rb'
include UtilityFunctions

$DEBUG = true

class Delegate
	def evaled_method_delegate;  :evaled_method_delegate;  end
	def closure_method_delegate; :closure_method_delegate; end
	def evaled_ivar_delegate;    :evaled_ivar_delegate;    end
	def closure_ivar_delegate;   :closure_ivar_delegate;   end
end

class TestClass

	def self::make_evaled_method_delegator( delegate, name )
		code = <<-END_CODE
		lambda {|*args| self.#{delegate}.#{name}(*args) }
		END_CODE

		return eval( code )
	end

	def self::make_closure_method_delegator( delegate, name )
		return Proc.new {|*args|
			self.send( delegate ).send( name, *args )
		}
	end

	def self::make_evaled_ivar_delegator( ivar, name )
		code = <<-END_CODE
		lambda {|*args| #{ivar}.#{name}(*args) }
		END_CODE

		return eval( code )
	end

	def self::make_closure_ivar_delegator( ivar, name )
		return Proc.new {|*args|
			self.instance_variable_get( ivar ).send( name, *args )
		}
	end

	def initialize
		@delegate = Delegate.new
	end

	attr_reader :delegate

	begin
		block = make_evaled_method_delegator( :delegate, :evaled_method_delegate )
		define_method( :evaled_method_delegate, &block )
	end
	begin
		block = make_closure_method_delegator( :delegate, :closure_method_delegate )
		define_method( :closure_method_delegate, &block )
	end
	begin
		block = make_evaled_ivar_delegator( :@delegate, :evaled_ivar_delegate )
		define_method( :evaled_ivar_delegate, &block )
	end
	begin
		block = make_closure_ivar_delegator( :@delegate, :closure_ivar_delegate )
		define_method( :closure_ivar_delegate, &block )
	end
end


obj = TestClass.new
ITERATIONS = 500_000

Benchmark.bmbm do |bench|
	bench.report( "evaled_method" )  { ITERATIONS.times {obj.evaled_method_delegate} }
	bench.report( "closure_method" ) { ITERATIONS.times {obj.closure_method_delegate} }
	bench.report( "evaled_ivar" )    { ITERATIONS.times {obj.evaled_ivar_delegate} }
	bench.report( "closure_ivar" )   { ITERATIONS.times {obj.closure_ivar_delegate} }
end


# Rehearsal --------------------------------------------------
# evaled_method    0.710000   0.000000   0.710000 (  0.727237)
# closure_method   0.980000   0.010000   0.990000 (  0.989009)
# evaled_ivar      0.680000   0.000000   0.680000 (  0.688548)
# closure_ivar     0.950000   0.010000   0.960000 (  0.961915)
# ----------------------------------------- total: 3.340000sec
# 
#                      user     system      total        real
# evaled_method    0.720000   0.000000   0.720000 (  0.727356)
# closure_method   0.990000   0.010000   1.000000 (  1.003005)
# evaled_ivar      0.680000   0.010000   0.690000 (  0.696292)
# closure_ivar     0.950000   0.000000   0.950000 (  0.968510)

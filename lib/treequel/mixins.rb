#!/usr/bin/ruby

require 'rbconfig'
require 'erb'
require 'etc'
require 'logger'

require 'treequel'


#--
# A collection of mixins shared between Treequel classes. Stolen mostly from ThingFish.
#
module Treequel # :nodoc:

	# 
	# Add logging to a Treequel class. Including classes get #log and #log_debug methods.
	# 
	# == Version
	#
	#  $Id$
	#
	# == Authors
	#
	# * Michael Granger <mgranger@laika.com>
	#
	# :include: LICENSE
	#
	# --
	#
	# Please see the file LICENSE in the 'docs' directory for licensing details.
	#
	module Loggable

		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }

		### A logging proxy class that wraps calls to the logger into calls that include
		### the name of the calling class.
		class ClassNameProxy # :nodoc:

			### Create a new proxy for the given +klass+.
			def initialize( klass, force_debug=false )
				@classname   = klass.name
				@force_debug = force_debug
			end
			
			### Delegate calls the global logger with the class name as the 'progname' 
			### argument.
			def method_missing( sym, msg=nil, &block )
				return super unless LEVEL.key?( sym )
				sym = :debug if @force_debug
				Treequel.logger.add( LEVEL[sym], msg, @classname, &block )
			end
		end # ClassNameProxy

		#########
		protected
		#########

		### Return the proxied logger.
		def log
			@log_proxy ||= ClassNameProxy.new( self.class )
		end

		### Return a proxied "debug" logger that ignores other level specification.
		def log_debug
			@log_debug_proxy ||= ClassNameProxy.new( self.class, true )
		end
	end # module Loggable


	### A collection of utilities for working with Hashes.
	module HashUtilities

		# Recursive hash-merge function
		HashMergeFunction = Proc.new {|key, oldval, newval|
			case oldval
			when Hash
				case newval
				when Hash
					oldval.merge( newval, &HashMergeFunction )
				else
					newval
				end

			when Array
				case newval
				when Array
					oldval | newval
				else
					newval
				end

			else
				newval
			end
		}

		###############
		module_function
		###############

		### Return a version of the given +hash+ with its keys transformed
		### into Strings from whatever they were before.
		def stringify_keys( hash )
			newhash = {}

			hash.each do |key,val|
				if val.is_a?( Hash )
					newhash[ key.to_s ] = stringify_keys( val )
				else
					newhash[ key.to_s ] = val
				end
			end

			return newhash
		end


		### Return a duplicate of the given +hash+ with its identifier-like keys
		### transformed into symbols from whatever they were before.
		def symbolify_keys( hash )
			newhash = {}

			hash.each do |key,val|
				keysym = key.to_s.dup.untaint.to_sym

				if val.is_a?( Hash )
					newhash[ keysym ] = symbolify_keys( val )
				else
					newhash[ keysym ] = val
				end
			end

			return newhash
		end
		alias_method :internify_keys, :symbolify_keys

	end
	

	### A collection of utilities for working with Arrays.
	module ArrayUtilities

		###############
		module_function
		###############

		### Return a version of the given +array+ with any Symbols contained in it turned into
		### Strings.
		def stringify_array( array )
			return array.collect do |item|
				case item
				when Symbol
					item.to_s
				when Array
					stringify_array( item )
				else
					item
				end
			end
		end


		### Return a version of the given +array+ with any Strings contained in it turned into
		### Symbols.
		def symbolify_array( array )
			return array.collect do |item|
				case item
				when String
					item.to_sym
				when Array
					symbolify_array( item )
				else
					item
				end
			end
		end

	end
	

end # module Treequel

# vim: set nosta noet ts=4 sw=4:


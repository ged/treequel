#!/usr/bin/ruby

require 'rbconfig'
require 'erb'
require 'etc'
require 'logger'

require 'treequel'
require 'treequel/constants'


module Treequel

	# A collection of various delegation code-generators that can be used to define
	# delegation through other methods, to instance variables, etc.
	module Delegation

		###############
		module_function
		###############

		### Define the given +delegated_methods+ as delegators to the like-named method
		### of the return value of the +delegate_method+.
		### 
		### @example
		###    class MyClass
		###      extend Treequel::Delegation
		###      
		###      # Delegate the #bound?, #err, and #result2error methods to the connection
		###      # object returned by the #connection method. This allows the connection
		###      # to still be loaded on demand/overridden/etc.
		###      def_method_delegators :connection, :bound?, :err, :result2error
		###      
		###      def connection
		###        @connection ||= self.connect
		###      end
		###    end
		### 
		def def_method_delegators( delegate_method, *delegated_methods )
			delegated_methods.each do |name|
				body = make_method_delegator( delegate_method, name )
				define_method( name, &body )
			end
		end


		### Define the given +delegated_methods+ as delegators to the like-named method
		### of the specified +ivar+. This is pretty much identical with how 'Forwardable'
		### from the stdlib does delegation, but it's reimplemented here for consistency.
		### 
		###    class MyClass
		###      extend Treequel::Delegation
		###      
		###      # Delegate the #each method to the @collection ivar
		###      def_ivar_delegators :@collection, :each
		###      
		###    end
		### 
		def def_ivar_delegators( ivar, *delegated_methods )
			delegated_methods.each do |name|
				body = make_ivar_delegator( ivar, name )
				define_method( name, &body )
			end
		end


		#######
		private
		#######

		### Make the body of a delegator method that will delegate to the +name+ method
		### of the object returned by the +delegate+ method.
		def make_method_delegator( delegate, name )
			error_frame = caller(4)[0]
			file, line = error_frame.split( ':', 2 )

			# Ruby can't parse obj.method=(*args), so we have to special-case setters...
			if name.to_s =~ /(\w+)=$/
				name = $1
				code = <<-END_CODE
				lambda {|*args| self.#{delegate}.#{name} = *args }
				END_CODE
			else
				code = <<-END_CODE
				lambda {|*args| self.#{delegate}.#{name}(*args) }
				END_CODE
			end

			return eval( code, nil, file, line.to_i )
		end


		### Make the body of a delegator method that will delegate calls to the +name+
		### method to the given +ivar+.
		def make_ivar_delegator( ivar, name )
			error_frame = caller(4)[0]
			file, line = error_frame.split( ':', 2 )

			# Ruby can't parse obj.method=(*args), so we have to special-case setters...
			if name.to_s =~ /(\w+)=$/
				name = $1
				code = <<-END_CODE
				lambda {|*args| #{ivar}.#{name} = *args }
				END_CODE
			else
				code = <<-END_CODE
				lambda {|*args| #{ivar}.#{name}(*args) }
				END_CODE
			end

			return eval( code, nil, file, line.to_i )
		end

	end # module Delegation


	# A collection of key-normalization functions for various artifacts in LDAP like
	# attribute names, objectclass OIDs, etc.
	module Normalization

		###############
		module_function
		###############

		### Normalize the given key
		### @param [String] key  the key to normalize
		### @return a downcased Symbol stripped of any invalid characters, and 
		###         with '-' characters converted to '_'.
		def normalize_key( key )
			return key if key.to_s =~ Treequel::Constants::Patterns::NUMERICOID
			return key.to_s.downcase.
				gsub( /[^[:alnum:]\-_]/, '' ).
				gsub( '-', '_' ).
				to_sym
		end

		### Return a copy of +hash+ with all of its keys normalized by #normalize_key.
		### @param [Hash] hash  the Hash to normalize
		def normalize_hash( hash )
			hash = hash.dup
			hash.keys.each do |key|
				nkey = normalize_key( key )
				hash[ nkey ] = hash.delete( key ) if key != nkey
			end

			return hash
		end


	end # Normalization


	### Add logging to a Treequel class. Including classes get #log and #log_debug methods.
	module Loggable

		### A logging proxy class that wraps calls to the logger into calls that include
		### the name of the calling class.
		### @private
		class ClassNameProxy

			### Create a new proxy for the given +klass+.
			def initialize( klass, force_debug=false )
				@classname   = klass.name
				@force_debug = force_debug
			end

			### Delegate debug messages to the global logger with the appropriate class name.
			def debug( msg=nil, &block )
				Treequel.logger.add( Logger::DEBUG, msg, @classname, &block )
			end

			### Delegate info messages to the global logger with the appropriate class name.
			def info( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Treequel.logger.add( Logger::INFO, msg, @classname, &block )
			end

			### Delegate warn messages to the global logger with the appropriate class name.
			def warn( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Treequel.logger.add( Logger::WARN, msg, @classname, &block )
			end

			### Delegate error messages to the global logger with the appropriate class name.
			def error( msg=nil, &block )
				return self.debug( msg, &block ) if @force_debug
				Treequel.logger.add( Logger::ERROR, msg, @classname, &block )
			end

			### Delegate fatal messages to the global logger with the appropriate class name.
			def fatal( msg=nil, &block )
				Treequel.logger.add( Logger::FATAL, msg, @classname, &block )
			end

		end # ClassNameProxy

		#########
		protected
		#########

		### Copy constructor -- clear the original's log proxy.
		def initialize_copy( original )
			@log_proxy = @log_debug_proxy = nil
			super
		end

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


		# Recursive hash-merge function
		def merge_recursively( key, oldval, newval )
			case oldval
			when Hash
				case newval
				when Hash
					oldval.merge( newval, &method(:merge_recursively) )
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
		end

	end # HashUtilities


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

	end # module ArrayUtilities


	### A collection of attribute declaration functions
	module AttributeDeclarations

		###############
		module_function
		###############

		### Declare predicate accessors for the attributes associated with the specified
		### +symbols+.
		def predicate_attr( *symbols )
			symbols.each do |attrname|
				define_method( "#{attrname}?" ) do
					instance_variable_defined?( "@#{attrname}" ) &&
						instance_variable_get( "@#{attrname}" ) ? true : false
				end
				define_method( "#{attrname}=" ) do |newval|
					instance_variable_set( "@#{attrname}", newval ? true : false )
				end
				alias_method "is_#{attrname}?", "#{attrname}?"
			end
		end

	end # module AttributeDeclarations


	### A collection of ANSI color utility functions
	module ANSIColorUtilities

		# Set some ANSI escape code constants (Shamelessly stolen from Perl's
		# Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
		ANSI_ATTRIBUTES = {
			'clear'      => 0,
			'reset'      => 0,
			'bold'       => 1,
			'dark'       => 2,
			'underline'  => 4,
			'underscore' => 4,
			'blink'      => 5,
			'reverse'    => 7,
			'concealed'  => 8,

			'black'      => 30,   'on_black'   => 40,
			'red'        => 31,   'on_red'     => 41,
			'green'      => 32,   'on_green'   => 42,
			'yellow'     => 33,   'on_yellow'  => 43,
			'blue'       => 34,   'on_blue'    => 44,
			'magenta'    => 35,   'on_magenta' => 45,
			'cyan'       => 36,   'on_cyan'    => 46,
			'white'      => 37,   'on_white'   => 47
		}

		###############
		module_function
		###############

		### Create a string that contains the ANSI codes specified and return it
		def ansi_code( *attributes )
			attributes.flatten!
			attributes.collect! {|at| at.to_s }
			return '' unless /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i =~ ENV['TERM']
			attributes = ANSI_ATTRIBUTES.values_at( *attributes ).compact.join(';')

			if attributes.empty?
				return ''
			else
				return "\e[%sm" % attributes
			end
		end


		### Colorize the given +string+ with the specified +attributes+ and return it, handling 
		### line-endings, color reset, etc.
		def colorize( *args )
			string = ''

			if block_given?
				string = yield
			else
				string = args.shift
			end

			ending = string[/(\s)$/] || ''
			string = string.rstrip

			return ansi_code( args.flatten ) + string + ansi_code( 'reset' ) + ending
		end

	end # module ANSIColorUtilities

end # module Treequel

# vim: set nosta noet ts=4 sw=4:


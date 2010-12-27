#!/usr/bin/env ruby
# coding: utf-8

require 'treequel'
require 'treequel/model'
require 'treequel/mixins'
require 'treequel/constants'


# Mixin that provides Treequel::Model characteristics to a mixin module.
# 
# The ideas and a large portion of the implementation of this class is borrowed from
# Sequel under the following license terms:
# 
#     Copyright (c) 2007-2008 Sharon Rosner
#     Copyright (c) 2008-2010 Jeremy Evans
#     
#     Permission is hereby granted, free of charge, to any person obtaining a copy
#     of this software and associated documentation files (the "Software"), to
#     deal in the Software without restriction, including without limitation the
#     rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#     sell copies of the Software, and to permit persons to whom the Software is
#     furnished to do so, subject to the following conditions:
#       
#     The above copyright notice and this permission notice shall be included in
#     all copies or substantial portions of the Software.
#        
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#     THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
#     IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#     CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
class Treequel::Model::Errors < ::Hash
	include Treequel::HashUtilities,
	        Treequel::Loggable

	# The word to use between attributes in error messages
	ATTRIBUTE_CONJUNCTION = ' and '


	### Set the initializer block to auto-create Array values.
	def initialize( *args )
		block = lambda {|h,k| h[k] = [] }
		super( *args, &block )
	end


	### Adds an error for the given +attribute+.
	### @param [Symbol, #to_sym] attribute  the attribute with an error
	### @param [String] message             the description of the error condition
	def add( attribute, message )
		self[ attribute ] << message
	end


	### Get the number of errors that have been registered.
	### @Return [Fixnum]  the number of errors
	def count
		return self.values.inject( 0 ) {|num, val| num + val.length }
	end


    ### Get an Array of messages describing errors which have occurred.
    ### @example
    ###   errors.full_messages
    ###   # => ['cn is not valid',
    ###   #     'uid is not at least 2 letters']
	def full_messages
		return self.inject([]) do |full_messages, (attribute, messages)|
			subject = Array( attribute ).join( ATTRIBUTE_CONJUNCTION )
			messages.each {|part| full_messages << "#{subject} #{part}" }
			full_messages
		end
	end

end # class Treequel::Model::Errors


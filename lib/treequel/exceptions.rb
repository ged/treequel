#!/usr/bin/env ruby

require 'treequel'


# A collection of exceptions for Treequel.
# 
# == Subversion Id
#
#  $Id$
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# :include: LICENSE
#
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel

	### The base Treequel exception type
	class Error < ::RuntimeError; end

	### Schema parsing errors
	class ParseError < Treequel::Error; end

end # module Treequel



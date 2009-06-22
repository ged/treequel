#!/usr/bin/env ruby

require 'time'

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'


# A wrapper around the connection to the LDAP server that handles
# reconnect attempts, normalizes exceptions, and referrals.
#
# == Subversion Id
#
#  $Id$
#
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
#
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Connection
	include Treequel::Loggable,
	        Treequel::Constants

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default number of times to attempt to reconnect
	DEFAULT_RETRY_LIMIT = 5

	# The default number of seconds after which the connection retry counter resets.
	DEFAULT_RETRY_LIMIT_TIMEOUT = 5


	

end # class Treequel::Connection



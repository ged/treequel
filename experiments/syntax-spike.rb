#!/usr/bin/env ruby

# An experiment to see what kind of DSL would be useful for building
# LDAP "datasets" like Sequel's SQL datasets.

require 'ldap'
require 'uri'
require 'forwardable'
require 'pp'
require 'pathname'

require Pathname( __FILE__ ).dirname + 'utils.rb'
include UtilityFunctions

$DEBUG = true

module TreequelSpike

	class Branch
		extend Forwardable

		def self::new_from_dn( dir, dn )
			path = dn.sub( /#{dir.base}$/, '' )
			return path.split(/,/).reverse.inject( dir ) do |prev, pair|
				attribute, value = pair.split( /=/, 2 )
				debug_msg "new_from_dn: fetching %s=%s from %p" % [ attribute, value, prev ]
				prev.send( attribute, value )
			end
		end

		def initialize( dir, attribute, value, base, entry=nil )
			@dir       = dir
			@attribute = attribute
			@value     = value
			@base      = base
			@entry     = nil
		end

		def_delegators :@dir, :bind, :bound?

		attr_reader :dir, :attribute, :value, :base

		def method_missing( sym, *args )
			return self.class.new( @dir.dup, sym, args.first, self.dn )
		end

		def attr_pair
			return [ self.attribute, self.value ].join('=')
		end

		def dn
			return [self.attr_pair, self.base].join(',')
		end
		alias_method :to_s, :dn

		def entry
			@entry ||= self.dir.get_entry( self )
		end

		def inspect
			return "#<%s:0x%0x %s @ %s %p>" % [
				self.class.name,
				self.object_id * 2,
				self.dn,
				self.dir,
				self.entry,
			  ]
		end

		def filter( filterstring )
			return self.dir.search( self.dn, LDAP::LDAP_SCOPE_SUBTREE, filterstring )
		end

		def +( other )
			debug_msg "%p + %p" % [ self, other ]
			return TreequelSpike::BranchCollection.new( self, other )
		end
	end


	class BranchCollection
		def self::def_multi_methods( *names )
			names.each do |name|
				define_method( name ) do |*args|
					self.multi_exec( name, *args )
				end
			end
		end


		def initialize( left_branches, right_branches )
			@branches = ( [left_branches] + [right_branches] ).flatten
		end

		attr_reader :branches

		def multi_exec( op, *args )
			res = @branches.collect {|br| br.send(op, *args) }.flatten
		end

		def +( other )
			if other.respond_to?( :branches )
				return self.class.new( self.branches, other.branches )
			else
				return self.class.new( self.branches, [other] )
			end
		end

		def_multi_methods :filter
	end


	class Directory

		DEFAULT_OPTIONS = {
			:host         => 'localhost',
			:port         => LDAP::LDAP_PORT,
			:connect_type => :plain,
			:base         => 'o=Acme',
		}

		def initialize( options )
			@options = DEFAULT_OPTIONS.merge( options )

			@host         = @options[:host]
			@port         = @options[:port]
			@connect_type = @options[:connect_type]
			@base         = @options[:base]

			@conn = nil
			@bound_as = nil
		end

		attr_reader :host, :port, :connect_type, :base

		def to_s
			bindname = self.bound? ? self.bound_as : "unbound"
			bindname ||= 'anonymous'

			return "%s:%d (%s, %s)" % [
				self.host,
				self.port,
				self.connect_type,
				bindname
			  ]
		end

		def conn
			return @conn ||= self.connect
		end

		def connect
			case @connect_type
			when :tls
				debug_msg "Connecting using TLS to %s:%d" % [ @host, @port ]
				return LDAP::SSLConn.new( @host, @port, true )
			when :ssl
				debug_msg "Connecting using SSL to %s:%d" % [ @host, @port ]
				return LDAP::SSLConn.new( host, port )
			else
				debug_msg "Connecting using an unencrypted connection to %s:%d" % [ @host, @port ]
				return LDAP::Conn.new( host, port )
			end
		end


		def bind( as=nil, password=nil, &block )
			if as.nil?
				debug_msg "Binding anonymously"
				self.conn.bind( nil, nil, LDAP::LDAP_AUTH_SIMPLE, &block )
				@bound_as = nil
			else
				debug_msg "Binding as: %s" % [ as.to_s ]
				self.conn.bind( as.to_s, password, &block )
				@bound_as = as.to_s
			end

			return "Bound as: %p" % [ @bound_as ]
		end

		def unbind
			self.conn.unbind
		end

		def bound?
			return self.conn.bound?
		end

		def get_entry( branch )
			self.conn.search2( branch.base, LDAP::LDAP_SCOPE_ONELEVEL, branch.attr_pair ).first
		end

		def search( base_dn, scope, filter )
			return self.conn.search2( base_dn, scope, filter ).collect do |row|
				TreequelSpike::Branch.new_from_dn( self.dup, row['dn'].first )
			end
		end

		def method_missing( sym, *args )
			return TreequelSpike::Branch.new( self.dup, sym, args.first, self.base )
		end

	end # class Directory


	###############
	module_function
	###############

	def directory( options )
		return TreequelSpike::Directory.new( options )
	end

end # module TreequelSpike


directory_params = {
	:connect_type => :tls,
	:host => 'gont.ljc.acme.com',
	:base => 'dc=acme,dc=com',
}

dir = TreequelSpike.directory( directory_params )
# => #<Treequel::Directory:0x49f2dc
#     @base="dc=acme,dc=com",
#     @bound_as=nil,
#     @conn=nil,
#     @connect_type=:tls,
#     @host="gont.ljc.acme.com",
#     @options=
#      {:base=>"dc=acme,dc=com",
#       :host=>"gont.ljc.acme.com",
#       :port=>389,
#       :connect_type=>:tls},
#     @port=389>

# By default, anonymous binding...

# ...but you can set a default binding
dir.bind( dir.ou(:people).uid(:mgranger), "foobar" )
# => "Bound as: \"uid=mgranger,ou=people,dc=acme,dc=com\""

# ...or bind as someone else for the duration of the block
# dir.bind( 'cn=auth,dc=acme,dc=com', "foobar" ) do
# 	dir.ou( :people ).uid( 'mgranger' )
# end


# Make a "dataset" out of the 'ou=departments,dc=acme,dc=com' branch
departments = dir.ou( :departments )
# => #<Treequel::Branch:0x49ac28 ou=departments,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Departments"], "objectClass"=>["organizationalUnit", "top"], "dn"=>["ou=Departments,dc=acme,dc=com"]}>

# Same thing, but for disparate branches
hosts = dir.ou( :hosts ) +
        dir.dc( :pettygrove ).ou( :hosts ) +
        dir.dc( :bennett ).ou( :hosts ) +
        dir.dc( :ljc ).ou( :hosts )
# => #<Treequel::Branch:0x498f40 ou=hosts,dc=ljc,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Hosts"], "objectClass"=>["organizationalUnit", "top"], "dn"=>["ou=Hosts,dc=ljc,dc=acme,dc=com"]}>

hosts
# => #<Treequel::BranchCollection:0x498428
#     @branches=
#      [#<Treequel::Branch:0x49a0ac ou=hosts,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Hosts"], "objectClass"=>["top", "organizationalUnit"], "dn"=>["ou=Hosts,dc=acme,dc=com"]}>,
#       #<Treequel::Branch:0x49a034 ou=hosts,dc=pettygrove,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Hosts"], "objectClass"=>["organizationalUnit", "top"], "dn"=>["ou=Hosts,dc=pettygrove,dc=acme,dc=com"]}>,
#       #<Treequel::Branch:0x4991d4 ou=hosts,dc=bennett,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Hosts"], "objectClass"=>["top", "organizationalUnit"], "dn"=>["ou=Hosts,dc=bennett,dc=acme,dc=com"]}>,
#       #<Treequel::Branch:0x498f40 ou=hosts,dc=ljc,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"ou"=>["Hosts"], "objectClass"=>["organizationalUnit", "top"], "dn"=>["ou=Hosts,dc=ljc,dc=acme,dc=com"]}>]>

hosts.filter( "(|(ipHostNumber=10.111.222.66)(ipHostNumber=10.4.1.194))" )
# => [#<Treequel::Branch:0x494a08 cn=leroy,ou=Hosts,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"cn"=>["leroy"], "macAddress"=>["00:e0:18:90:9f:16"], "description"=>["Provides vinton.com e-mail forwarding"], "ipHostNumber"=>["10.111.222.66"], "objectClass"=>["top", "device", "ipHost", "acmeHost", "ieee802Device"], "owner"=>["cn=isg,ou=Lists,dc=acme,dc=com"], "dn"=>["cn=leroy,ou=Hosts,dc=acme,dc=com"]}>,
#     #<Treequel::Branch:0x492ce4 cn=zelda,ou=Hosts,dc=pettygrove,dc=acme,dc=com @ gont.ljc.acme.com:389 (tls, bound_as=,dc=acme,dc=com) {"cn"=>["zelda"], "macAddress"=>["00:13:72:d1:a0:0f"], "description"=>["workstation"], "ipHostNumber"=>["10.4.1.194"], "objectClass"=>["top", "acmeHost", "ipHost", "ieee802Device", "device"], "owner"=>["cn=isg,ou=Lists,dc=acme,dc=com"], "dn"=>["cn=zelda,ou=Hosts,dc=pettygrove,dc=acme,dc=com"]}>]

departments.filter( :and,
	[:supervisor, nil],
	[ :not, [:uniqueMembers, '']] )


mahlon = dir.ou( :people ).uid( :mahlon )
mahlon.copy( 'othermahlon' )

dir.ou( people ) << { :uid => 'othermahlon', :sn => 'Bonch' }





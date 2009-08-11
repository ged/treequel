#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'rubygems'
require 'sinatra'
require 'treequel'
require 'erb'

include ERB::Util

# The real data is all in operational attributes, so fetch them by default
Treequel::Branch.include_operational_attrs = true

set :root, Pathname( __FILE__ ).dirname + 'ldap-monitor'


before do
	@monitor ||= Treequel.directory( 'ldap://localhost/cn=Monitor',
		:bind_dn => 'cn=admin,cn=Monitor', :pass => 'monitor' )
end


### GET /
get '/' do
	erb :index,
		:locals => {
			:server_info => @monitor.base['monitoredInfo'],
			:datapoints  => @monitor.children,
		}
end


# 
# Subsystems
# 

get '/connections' do
	connections = @monitor.cn( :connections )

	erb :connections,
		:locals => {
			:subsystem => connections,
			:total => connections.cn( :total ),
			:current => connections.cn( :current ),
			:conninfo => connections.children
		}
end


### Fallback handler for subsystems
get '/:subsystem' do
	branch = @monitor.cn( params[:subsystem] )
	erb :dump_subsystem,
		:locals => {
			:subsystem => branch,
		}
end



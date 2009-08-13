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

helpers do

	### Return a string describing the amount of time in the given number of
	### seconds in terms a human can understand easily.
	def time_delta_string( start_time )
		start = Time.parse( start_time ) or return "some time"
		seconds = Time.now - start

		return 'less than a minute' if seconds < 60

		if seconds < 50 * 60
			return "%d minute%s" % [seconds / 60, seconds/60 == 1 ? '' : 's']
		end

		return 'about an hour'					if seconds < 90 * MINUTES
		return "%d hours" % [seconds / HOURS]	if seconds < 18 * HOURS
		return 'one day' 						if seconds <  1 * DAYS
		return 'about a day' 					if seconds <  2 * DAYS
		return "%d days" % [seconds / DAYS] 	if seconds <  1 * WEEKS
		return 'about a week' 					if seconds <  2 * WEEKS
		return "%d weeks" % [seconds / WEEKS] 	if seconds <  3 * MONTHS
		return "%d months" % [seconds / MONTHS] if seconds <  2 * YEARS
		return "%d years" % [seconds / YEARS]
	end

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

get '/backends' do
	subsystem = @monitor.cn( :backends )
	backends = subsystem.
		filter( :objectClass => :monitoredObject ).
		select( :+, :* )

	erb :backends,
		:locals => {
			:subsystem => subsystem,
			:backends => backends,
		}
end


get '/connections' do
	subsystem = @monitor.cn( :connections )
	connections = subsystem.
		filter( :objectClass => :monitorConnection ).
		select( :+, :* )

	erb :connections,
		:locals => {
			:subsystem => subsystem,
			:total => subsystem.cn( :total ),
			:current => subsystem.cn( :current ),
			:connections => connections.all,
		}
end


get '/databases' do
	subsystem = @monitor.cn( :databases )
	databases = subsystem.
		filter( :objectClass => :monitoredObject ).
		select( :+, :* )

	erb :databases,
		:locals => {
			:subsystem => subsystem,
			:databases => databases,
		}
end


get '/listeners' do
	subsystem = @monitor.cn( :listeners )
	listeners = subsystem.
		filter( :objectClass => :monitoredObject ).
		select( :+, :* )

	erb :listeners,
		:locals => {
			:subsystem => subsystem,
			:listeners => listeners,
		}
end


### Fallback handler for subsystems
get '/:subsystem' do
	subsystem = @monitor.cn( params[:subsystem] )
	contents = subsystem.
		filter( :objectClass => :monitoredObject ).
		select( :+, :* )

	erb :dump_subsystem,
		:locals => {
			:subsystem => subsystem,
			:contents => contents,
		}
end



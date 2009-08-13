#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'treequel'
require 'pathname'

# A barebones web-based company directory

LDAP_URL = "ldap://ldap.yourcompany.com/dc=yourcompany,dc=com"

configure do
	# Borrow the CSS and images from the 'ldap-monitor' example
	set :root, Pathname( __FILE__ ).dirname + 'ldap-monitor'
end

before do
	$stderr.puts "Connecting to #{LDAP_URL}"
	@ldap ||= Treequel.directory( LDAP_URL )
end


### GET /
get '/' do

	# Get every entry under ou=people that has an email address and sort them
	# by last name, first name, and UID.
	people = @ldap.ou( :people ).filter( :mail ).sort_by do |person|
		[ person[:sn], person[:givenName], person[:uid] ]
	end

	erb :index,
		:locals => {
			:people => people
		}
end


### GET /uid
get '/:uid' do

	# Look up the person associated with the given UID, returning NOT FOUND if
	# there isn't any such entry
	uid = params[:uid]
	person = @ldap.ou( :people ).uid( uid )
	halt 404, "No such person" unless person.exists?

	erb :details,
		:locals => {
			:person => person
		}
end



__END__

@@layout
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
	<title>Company Directory</title>
	<link rel="stylesheet" href="/css/master.css" type="text/css" media="screen" title="no title" charset="utf-8" />
</head>

<body>

	<div id="content">
	<h1>Company Directory</h1>

	<%= yield %>

	</div>

	<div id="footer">Treequel Company Directory Example</div>
</body>
</html>


@@index
<table>
<thead>
	<tr>
		<th class="odd">Name</th>
		<th class="even">Email</th>
		<th class="odd">Badge #</th>
	</tr>
</thead>
<tbody>
<% people.each_with_index do |person, i| %>
<% rowclass = i.divmod(2).last.zero? ? "even" : "odd" %>
	<tr class="<%= rowclass %>">
		<td class="odd"><a href="/<%= person[:uid] %>"><%= person[:cn] %></p></td>
		<td class="even"><a href="/<%= person[:uid] %>"><%= person[:mail] %></a></td>
		<td class="odd"><%= person[:employeeNumber] %></td>
	</tr>
<% end %>
</tbody>
</table>

@@details

<h2>Details for <%= person[:cn] %> <%= person[:sn] %> 
	&lt;<%= person[:mail] %>&gt;</h2>

<pre>
<%= person.to_ldif %>
</pre>


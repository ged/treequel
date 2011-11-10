#!/usr/bin/env ruby

require 'pp'
require 'rubygems'
require 'ldap'

# Trying to track down object corruption while running Treequel's specs:
#
# 1) Treequel::Model objects loaded from entries with several modified attributes can return the modifications as a list of LDAP::Mod objects
#    Failure/Error: result.should include( ldap_mod_delete :displayName, 'Slappy the Frog' )
#      expected [#<LDAP::Mod:0x1038328c8 LDAP_MOD_DELETE
#      {"\236\303\247\002\001"=>["Alright."]}>, #<LDAP::Mod:0x103832760 LDAP_MOD_ADD
#      {"\363\257\244\002\001"=>["The new mascot."]}>, #<LDAP::Mod:0x103830488 LDAP_MOD_DELETE
#      {"MX}\002\001"=>["Slappy the Frog"]}>, #<LDAP::Mod:0x1038302f8 LDAP_MOD_ADD
#      {"3H\324\003\001"=>["Fappy the Bear"]}>, #<LDAP::Mod:0x10382ce50 LDAP_MOD_DELETE
#      {"\260\"\202\002\001"=>["Slappy"]}>, #<LDAP::Mod:0x10382cc20 LDAP_MOD_ADD
#      {"s\354s\002\001"=>["Fappy"]}>, #<LDAP::Mod:0x10382baf0 LDAP_MOD_DELETE
#      {"\252\3413\004\001"=>["a forest in England"]}>, #<LDAP::Mod:0x1038201f0 LDAP_MOD_DELETE
#      {"S}b\002\001"=>["slappy"]}>, #<LDAP::Mod:0x103820060 LDAP_MOD_ADD
#      {"$\357\302\003\001"=>["fappy"]}>] to include #<LDAP::Mod:0x103806d68 LDAP_MOD_DELETE
#      {"displayName"=>["Slappy the Frog"]}>
#      Diff:
#      @@ -1,3 +1,19 @@
#      -#<LDAP::Mod:0x103806d68 LDAP_MOD_DELETE
#      -{"displayName"=>["Slappy the Frog"]}>
#      +[#<LDAP::Mod:0x1038328c8 LDAP_MOD_DELETE
#      +{"\236\303\247\002\001"=>["Alright."]}>,
#      + #<LDAP::Mod:0x103832760 LDAP_MOD_ADD
#      +{"\363\257\244\002\001"=>["The new mascot."]}>,
#      + #<LDAP::Mod:0x103830488 LDAP_MOD_DELETE
#      +{"MX}\002\001"=>["Slappy the Frog"]}>,
#      + #<LDAP::Mod:0x1038302f8 LDAP_MOD_ADD
#      +{"3H\324\003\001"=>["Fappy the Bear"]}>,
#      + #<LDAP::Mod:0x10382ce50 LDAP_MOD_DELETE
#      +{"\260\"\202\002\001"=>["Slappy"]}>,
#      + #<LDAP::Mod:0x10382cc20 LDAP_MOD_ADD
#      +{"s\354s\002\001"=>["Fappy"]}>,
#      + #<LDAP::Mod:0x10382baf0 LDAP_MOD_DELETE
#      +{"\252\3413\004\001"=>["a forest in England"]}>,
#      + #<LDAP::Mod:0x1038201f0 LDAP_MOD_DELETE
#      +{"S}b\002\001"=>["slappy"]}>,
#      + #<LDAP::Mod:0x103820060 LDAP_MOD_ADD
#      +{"$\357\302\003\001"=>["fappy"]}>]
#    # ./spec/treequel/model_spec.rb:634
# 

# And then the monkeypatch to work around the problem:
class LDAP::Mod

	alias :_initialize_ext :initialize
	remove_method :initialize

	### Override the initializer to keep the +attribute+ around while the object
	### is alive to prevent the underlying C String pointer from going away.
	### See line 151 of mod.c.
	def initialize( op, attribute, vals )
		@attribute = attribute
		_initialize_ext( op, attribute, vals )
	end

end # class LDAP::Mod


GC.stress = true # Garbage-collect after every object-allocation (1.9 only)
mods = []

mods << LDAP::Mod.new(LDAP::LDAP_MOD_DELETE, "description", ["Alright."])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_ADD, "description", ["The new mascot."])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_DELETE, "displayName", ["Slappy the Frog"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_ADD, "displayName", ["Fappy the Bear"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_DELETE, "givenName", ["Slappy"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_ADD, "givenName", ["Fappy"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_DELETE, "l", ["a forest in England"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_DELETE, "uid", ["slappy"])
mods << LDAP::Mod.new(LDAP::LDAP_MOD_ADD, "uid", ["fappy"])

pp mods

#
# This succesfully replicates the problem, which is a bug in ruby-ldap's
# mod.c. The attribute type is set to the char * of a Ruby String
# instead of strdup()ing it or something, so when the String is later
# garbage-collected, the underlying char * is pointing somewhere else.
#


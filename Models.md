---
title: Models
layout: default
index: 7
filters:
  - erb
  - links
  - examples
  - editorial
  - api
  - textile
example_prelude: |-
  require 'treequel'
  dir = Treequel.directory
---

<div id="auto-toc"></div>

h2(#models). Models

A common pattern when you're using any kind of datastore is to represent the data contained within it as a "domain model":http://www.martinfowler.com/eaaCatalog/domainModel.html. For relational databases, Martin Fowler's "Active Record" pattern has become the _de facto_ standard, and because of its popularity, a few people have tried to apply the same pattern to LDAP. However, LDAP records aren't of fixed dimensionality, and don't need to be grouped together in the directory, so applying the logic of relational sets only works for the simplest cases.

Treequel comes with its own set of tools for constructing domain models, tools that take advantage of Ruby's flexible object model to reflect the flexibility and organic nature of LDAP data.


h3(#modeling-objectclass). Modeling ObjectClasses

The principle component is a class called <?api Treequel::Model ?>, which provides the usual attribute accessors for the entry that it wraps, as well as a mechanism for layering functionality onto an object based on what its @objectClass@ attributes are.

The layers are mixin Modules that extend <?api Treequel::Model::ObjectClass ?>, each of which is associated with a particular combination of objectClasses and bases. Here's a fairly simple example that adds a method that expands any _labeledUri_ attributes of entries under @ou=people,dc=acme,dc=com@ that have the @inetOrgPerson@ objectClass:

<?example { language: ruby, caption: "Add url-expansion to @inetOrgPerson@ entries." } ?>
require 'treequel/model'
require 'treequel/model/objectclass'

module ACME::InetOrgPerson
	extend Treequel::Model::ObjectClass

	model_class Treequel::Model
	model_bases 'ou=people,dc=acme,dc=com'
	model_objectclasses :inetOrgPerson


	### Return the person's URIs as values in a Hash keyed by either the
	### associated label (if there is one), or a number if there's no
	### label.
	def labeled_uris
		counter = 0
		return self.labeled_uri.inject({}) do |hash, luri|
			uri, label = luri.split( /\s+/, 2 )
			unless label
				label = counter
				counter += 1
			end
			hash[ label ] = URI( uri )
			hash
		end
	end

end # module ACME::InetOrgPerson

<?end?>

The module first extends Treequel::Model::ObjectClass [line 5], and then registers itself with a model class [line 7]. The next two lines set which objectClasses and base DNs the mixin will apply to [lines 8 and 9], and then the code that follows declares the method that's added to applicable model objects.

For example, if the above code was in a file called @acme/inetorgperson.rb@:

<?example { language: ruby, caption: "Get the labeledUris associated with the 'jonh' user." } ?>
require 'treequel/model'
require 'acme/inetorgperson'

Treequel::Model.directory = Treequel.directory_from_config
jonh = ACME::InetOrgPerson.filter( :uid => 'jonh' ).first
jonh.labeled_uris
# => {"My Homepage"=>#<URI::HTTP:0x00000102841f68 URL:http://example.com/>} 
<?end?>

h3(#model-associations). Model Associations

You can use the methods of the mixins to associate entries with one another, as well. For attributes that contain a full DN, fetching the value will automatically return another <?api Treequel::Model ?> instance, but for less-restrictive attributes like @memberUid@ that are just plain strings, you'll need to map them into the corresponding entry yourself:

<?example { language: ruby, caption: "Associate posixGroup memberUids with posixAccount uids." } ?>
require 'treequel/model'
require 'treequel/model/objectclass'

Treequel::Model.directory = Treequel.directory_from_config

module ACME::PosixAccount
	extend Treequel::Model::ObjectClass

	model_class Treequel::Model
	model_bases 'ou=people,dc=acme,dc=com'
	model_objectclasses :posixAccount

	### Return ACME::PosixGroup objects for the groups the account is a member of.
	def groups
		return ACME::PosixGroup.filter( :memberUid => self.uid ).all
	end

end # module ACME::PosixAccount


module ACME::PosixGroup
	extend Treequel::Model::ObjectClass

	model_class Treequel::Model
	model_bases 'ou=groups,dc=acme,dc=com'
	model_objectclasses :posixGroup

	### Return ACME::PosixAccount objects for the group's members
	def members
		return ACME::PosixAccount.filter( :uid => self.memberUid ).all
	end

end # module ACME::PosixGroup
<?end?>

If you want to make the associations a bit more useful, you can return a <?api Treequel::Branchset ?> from the association methods instead of calling @.all@ on it immediately, which will allow the results to be filtered further by chaining additional filter methods:

<?example { language: ruby, caption: "Find all sysadmin accounts that don't have a password." } ?>
require 'treequel/model'
require 'treequel/model/objectclass'

Treequel::Model.directory = Treequel.directory_from_config

# Re-open to modify the association to return a Branchset instead
module ACME::PosixGroup
	def members
		return ACME::PosixAccount.filter( :uid => self.memberUid )
	end
end # module ACME::PosixGroup

sysadmin_group = ACME::PosixGroup.filter( :cn => 'sysadmin' ).first
sysadmin_group.members.filter( ~:userPassword ).all

# => [#<Treequel::Model:0x100b0a2d8 uid=mahlon,ou=People,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>]
<?end ?>

Mahlon appears to be violating ACME Company policy [line 17]. He will be flogged in accordance with company handbook section C, paragraph 2.

If the functionality you wish to define requires attributes of two or more different _objectClasses_ , you can put all of them in the @model_objectclasses@ statement, and then the mixin will only apply to entries that have *all* of them. The @model_bases@ attribute can also take multiple values; entries will be limited to children of *any* of them.

h3(#saving-models). Saving Model Objects

Another difference between regular @Treequel::Branch@ objects and @Treequel::Model@ is that @Model@ objects defer writing attribute changes to the directory; while changes made to @Treequel::Branch@ are written immediately, @Treequel::Model@ objects keep track of modifications made to them, and only write them to the directory when their @Treequel::Model#save@ method is called.

h4(#model-validation). Model Validation

Before a @Model@ object is saved, it is first checked against its validations. Validations are a way of expressing additional constraints on values contained in an entry, or on the structure of entries themselves, constraints that are not always enforceable in the directory itself because attributes in LDAP are often free-form strings.

You define validations by overriding the @#validate@ method, and then adding to the object's @#errors@ if any problems are detected.

For example, if we wanted to be sure that the company's @posixAccount@ entries followed an established standard, we could add that like so:

<?example { language: ruby, caption: "Defining a custom validation." } ?>
require 'treequel/model/objectclass'

# Re-open the PosixAccount class from above to add validations
module ACME::PosixAccount

	def validate( options={} )
		# Enforce consistent home directory location based on first initial and uid
		expected_homedir = "/home/%s/%s" % [ self.uid[0,1], self.uid ]
		self.errors.add( :homeDirectory, "doesn't follow company convention" ) unless
			self.home_directory == expected_homedir

		# Make sure the account has a GECOS set, effectively treating a MAY attribute
		# as a MUST.
		self.errors.add( :gecos, "isn't set" ) unless self.gecos

		# Be sure to super so other validations run
		super
	end

end
<?end?>

You can check an object's validity at any time using the @Treequel::Model#valid?@ predicate. If it isn't valid, @Treequel::Model#errors@ will contain a <?api Treequel::Model::Errors ?> object that can be used to diagnose the problem, build error messages for display, etc.

<?example { language: ruby, caption: "Check a Model object for validity, and display error messages if it isn't valid." } ?>
require 'acme/posixaccount'

Treequel::Model.directory = Treequel.directory_from_config

# Create a new account
account = ACME::PosixAccount.create( 'uid=jbernam,ou=people,dc=acme,dc=com' )

account.cn = 'James Bernam'
account.uid_number = 511
account.gid_number = 500

unless account.valid?
	$stderr.puts "Couldn't save #{account}:",
		*account.errors.full_messages
end
<?end?>

Since the @posixAccount@ objectClass declares @homeDirectory@ as one of its @MUST@ attributes in the LDAP schema, this outputs:

bc. Couldn't save uid=jbernam,ou=people,dc=acme,dc=com:
homeDirectory MUST have a value
homeDirectory doesn't follow company convention
gecos isn't set

The default validations are provided by the @Treequel::Model::SchemaValidations@ module, and as its name suggests, they check the entry against the schema loaded from the directory. They are intended to prevent sending data to the directory that would result in a obvious error. If you want to skip them, you can pass the @:with_schema => false@ option to @#save@, @#valid?@, or @#validate@, which will still check any additional validations you've defined.

h4(#model-hooks). Model Callbacks

@Treequel::Model@ objects also call a number of callbacks during various stages of their lifecycle, letting you take actions by declaring one or more in an @ObjectClass@ mixin or in a @Treequel::Model@ subclass, if you wish them to be run for every instance. The hooks are (in the order they're typically executed):

* #after_initialize
* #before_validation
* #after_validation
* #before_save
* #before_create/#before_update
* #after_create/#after_update
* #after_save
* #before_destroy
* #after_destroy

Typically you'll use a hook to do things like encrypt sensitive data before saving, normalize specially-formatted values, fill in defaults, etc.

You can cause the hooked action to be aborted by returning a false value from any of the @before_@ hooks. This causes a @Treequel::BeforeHookFailed@ exception to be raised unless you call the action with @:raise_on_failure => false@.

Using hooks, you could rewrite the previous example like this:

<?example { language: ruby, caption: "Use exception-handling for catching failed saves." } ?>
require 'acme/posixaccount'

# Create a new account
account = ACME::PosixAccount.create( 'uid=jbernam,ou=people,dc=acme,dc=com' )

account.cn = 'James Bernam'
account.uid_number = 511
account.gid_number = 500

begin
	account.save
rescue Treequel::ValidationFailed => exception
	$stderr.puts "Couldn't save #{account}:",
		*exception.errors.full_messages
rescue Treequel::BeforeHookFailed => exception
	$stderr.puts "Couldn't save #{account}: the before_#{exception.hook} failed."
end
<?end?>


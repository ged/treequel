# Treequel: Connecting to a Directory

Once those things are done, you can fire Treequel up via IRb and get a  Treequel::Directory object to play around with:

    $ irb -rtreequel -rubygems
    irb> dir = Treequel.directory
    # => #<Treequel::Directory:0x69cbac localhost:389 (not connected) base="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>

The @.directory@ method has some reasonable defaults, so if your directory is running on localhost, you want to connect using @TLS@ on the default port, and bind anonymously, this will be all you need. 

For anything other than testing, though, it's likely you'll want to control the connection parameters a bit more than that. There are two options for doing this: via an "LDAP URL":http://tools.ietf.org/html/rfc4516, or with a @Hash@ of options.

h3(#connect-ldap-url). Connecting With an LDAP URL

The LDAP URL format can contain quite a lot of information, but @Treequel::Directory@ only uses the _scheme_, _host_, _port_, and _base DN_ parts:

<?example { language: irb, caption: "Fetching a directory by URL." } ?>
irb> dir = Treequel.directory( 'ldap://ldap.andrew.cmu.edu/dc=cmu,dc=edu' )
# => #<Treequel::Directory:0x4f052e ldap.andrew.cmu.edu:389 (not connected) base="dc=cmu,dc=edu", bound as=anonymous, schema=(schema not loaded)>
<?end?>

You may omit the base <abbr title="Distingished Name">DN</abbr> in the URL if your environment only has one top level base (or you don't know it!) Treequel will use the first base DN it finds from the server's advertised "namingContexts":http://tools.ietf.org/html/rfc4512#section-5.1.2 by default.

It will also use the user and password from a ==<code>user:pass@host</code>==-style URL, if present, and use them to immediately bind to the directory. See "the section on binding":#binding for details.

h3(#connect-options-hash). Connecting With an Options Hash

Creating a directory with an options hash allows more fine-grained control over the connection and binding parameters. It's the same as the hash supported by <?api Treequel::Directory ?>'s constructor:

- @:host@ := The LDAP host to connect to.
- @:port@ := The port to connect to.
- @:connect_type@ := The type of connection to establish. Must be one of @:plain@, @:tls@, or @:ssl@.
- @:base_dn@ := The base DN of the directory.
- @:bind_dn@ := The DN of the user to bind as.
- @:pass@ := The password to use when binding.

Any values which you don't provide will default to the values in @Treequel::Directory::DEFAULT_OPTIONS@.

<?example { language: irb, caption: "Fetching a directory with an options hash." } ?>
irb> dir = Treequel.directory( :host => 'localhost', :base_dn => 'dc=acme,dc=com' )
# => => #<Treequel::Directory:0x4f2586 localhost:389 (not connected) base="dc=acme,dc=com",    bound as=anonymous, schema=(schema not loaded)>
<?end?>

h3(#mixing-url-and-options-hash). Connecting with a URL and an Options Hash

You can also mix the two connection styles, allowing you to still use a compact URL, but set the @connection_type@ explicitly, e.g.:

<?example { language: irb, caption: "Using both a URL and options." } ?>
irb> dir = Treequel.directory( 'ldap://localhost/dc=acme,dc=com', :connect_type => :plain )
# => #<Treequel::Directory:0x4a0844 localhost:389 (not connected) base="dc=acme,dc=com",    bound as=anonymous, schema=(schema not loaded)>
<?end?>

h3(#connecting-with-system-settings). Connecting With System Settings

Very often, the host you're running on will already be using LDAP for something else, so it might not make sense to configure the connection again when you've already got all the information you need in the system settings.

Treequel supports using LDAP system settings to create new <?api Treequel::Directory ?> objects, too, using either OpenLDAP or 'nss_ldap' style configurations. To do this, call @Treequel.directory_from_config@ with the path to the config file you want to load:

<?example { language: irb, caption: "Load an OpenLDAP config file." } ?>
irb> Treequel.directory_from_config( '/usr/local/etc/openldap/ldap.conf' )
# => #<Treequel::Directory:0x4078db0c ldap.acme.com:389 (not connected) base_dn="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>
<?end?>

Or, just omit the argument and Treequel will search a bunch of common paths[1] for a config file and load the first one it finds:

<?example { language: irb, caption: "Load the config from a common path." } ?>
irb> Treequel.log.level = Logger::INFO
# => 1
irb> Treequel.directory_from_config
[2010-08-20 17:04:40.648875 41003/main]  INFO -- Searching common paths for ldap.conf
[2010-08-20 17:04:40.650592 41003/main]  INFO -- Reading config options from /etc/openldap/ldap.conf...
# => #<Treequel::Directory:0x4078db0c ldap.acme.com:389 (not connected) base_dn="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>
<?end?>

It also supports overriding elements of the LDAP configuration via OpenLDAP-style environment variables, too:

<?example { language: irb, caption: "Override the configured host to connect to the master." } ?>
irb> ENV['LDAPHOST'] = 'ldap-master.acme.com'
# => "ldap-master.acme.com"
irb> Treequel.directory_from_config( '/etc/openldap/ldap.conf' )
[2010-08-20 17:19:57.686113 41432/main]  INFO -- Reading config options from /etc/openldap/ldap.conf...
# => #<Treequel::Directory:0x4078c266 ldap-master.acme.com:389 (not connected) base_dn="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>
<?end?>

----
fn1. If there's one missing, let us know and we'll add it!
----


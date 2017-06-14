# Treequel: Binding to a Directory

If you don't specify a user <abbr title="Distingished Name">DN</abbr> and password, a new @Directory@ object will be bound anonymously, which is usually sufficient for reading the public attributes of records, but it's likely that you'll need to bind as a particular user to write to the directory or access protected attributes:

<?example { language: irb, caption: "Binding to the directory." } ?>
irb> dir.bind( 'uid=mgranger,ou=people,dc=acme,dc=com', 'my_password' )
# => "uid=mgranger,ou=people,dc=acme,dc=com"
<?end?>

You can also bind to the directory by creating it using a URL that contains _authority_ information; this is not recommended for production use, as it requires that the password be in plain text in the connection information, but it's supported for convenience's sake:

<?example { language: irb, caption: "Fetching a directory by URL with automatic binding." } ?>
irb> url = 'ldap://cn=user,dc=acme,dc=com:my_password@localhost/dc=acme,dc=com'
irb> dir = Treequel.directory( url )
# => #<Treequel::Directory:0x4f052e localhost:389 (not connected) base="dc=acme,dc=com", bound as="cn=user,dc=acme,dc=com", schema=(schema not loaded)>
<?end?>

h3(#unbinding). Unbinding

You can also revert back to an anonymous binding by calling @#unbind@.

h3(#rebinding). Binding With A Block

If you want to rebind as a different user for just a few operations, you can do that by calling the @#bound_as@ method with a block that contains the operations which require more privileges:

<?example { language: irb, caption: "Executing a block with a different binding." } ?>
irb> dir.bound_as( 'cn=admin,dc=acme,dc=com', 's00per:sekrit' ) { dir }
# => #<Treequel::Directory:0x4f052e localhost:389 (not connected) base="dc=acme,dc=com", bound as="cn=admin,dc=acme,dc=com", schema=(schema not loaded)>
<?end?>

Once the block returns, the binding reverts to what it previously was.

There are a bunch of other things you can do with the Directory object, but in most cases you won't interact with it directly except as the root of the directory. To interact with the entries in the directory, you'll probably want to start with a <?api Treequel::Branch ?>.


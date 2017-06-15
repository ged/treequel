# Treequel: Searching With \Branchsets

If you know exactly which entries you need, it's pretty easy to fetch the
corresponding Branch objects, but what if you need to search for entries
matching one or more criteria?

Searching is implemented in Treequel via Treequel::Branchset. Much like
[Datasets](http://sequel.rubyforge.org/rdoc/classes/Sequel/Dataset.html) from
the [Sequel library](http://sequel.rubyforge.org/) which inspired Treequel, a
Branchset is an object which represents an abstract set of records returned by
a search. The results of the search are returned on demand, so a Branchset can
be kept around and reused indefinitely.

You can construct a new Branchset via the usual constructor; it takes the
Branch for the base DN of the search:

    irb> Treequel::Branchset.new( dir.ou(:people) )
    # => #<Treequel::Branchset:0x1a418ec base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=0, timeout=0.000>

There are also several convenience methods on Branch and Directory that can create a new Branchset relative to themselves, as well:

    irb> dir.branchset
    # => #<Treequel::Branchset:0x1a3fc54 base_dn='dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=0, timeout=0.000>
    irb> dir.ou(:people).branchset
    # => #<Treequel::Branchset:0x1998314 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=0, timeout=0.000>

Like Sequel Datasets, Branchsets are meant to be chainable, so you can refine
what entries it will find by calling one of its mutators. Each mutator method
returns a new Branchset with the new criteria set. This allows you to build up
a query for what you need gradually, in a concise and flexible manner.


## Filter

The first of these mutators is Treequel::Branchset#filter.

You can narrow the results of that search by adding one or more filter
statements. Each call to `#filter` adds a clause to the LDAP filter string that
is eventually sent to the server.

With no modifications, a Branchset will find every entry below its base using a
filter of `(objectClass=*)` (which will match every entry).

The `#filter` method expects one or more expressions which are transformed into
an [LDAP filter](http://tools.ietf.org/html/rfc4515), and can be a literal
filter String, a Hash or an Array of criteria, or a Ruby expression.

The simplest of these, of course, is a literal LDAP filter in a `String`:

    irb> dir.ou( :people ).filter( '(objectClass=room)' )
    => #<Treequel::Branchset:0x12b7c48 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=room), scope=subtree, select=*, limit=0, timeout=0.000>

You can see what the equivalent filter of a Branchset is at any time using its
`#filter_string` method:

    irb> dir.ou( :people ).filter( '(objectClass=room)' ).filter_string
    # => "(objectClass=room)"

You can also use a `Hash` to do simple `attribute=value` matching:

    irb> dir.ou( :people ).filter( :givenName => 'Michael' ).filter_string
    # => "(givenName=Michael)"

Multiple criteria in a Hash will be ANDed together:

    irb> dir.ou( :people ).filter( :givenName => 'Michael', :sn => 'Granger' )
    # => "(&(givenName=Michael)(sn=Granger))"

You can include an OR in a filter by passing `:or` as the first element:

    irb> dir.ou( :people ).filter( :or, [:sn, 'Granger'], [:sn, 'Smith'] ).filter_string
    # => "(|(sn=Granger)(sn=Smith))"

or by specifying more than one value for a single attribute:

    # => #<Treequel::Directory:0x4e45d5 localhost:389 (connected) base_dn="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>
    irb> dir.ou( :people ).filter( :uid => [:mahlon, :mgranger, :jtran] ).filter_string

You can do the same with `:and` and `:not`, and combine them, too:

    irb> dir.ou( :people ).filter( :and, [:sn, 'Granger'], [:sn, 'Smith'] ).filter_string
    # => "(&(sn=Granger)(sn=Smith))"
    irb> dir.ou( :people ).filter( :not, [:and, [:sn, 'Granger'], [:sn, 'Smith']] ).filter_string
    # => "(!(&(sn=Granger)(sn=Smith)))"

Because `#filter` returns the mutated branchset, you can always chain them
together instead of using an explicit `:and`.

    irb> dir.ou( :people ).filter( :objectClass => 'inetOrgPerson' ).filter( :sn => 'Smith' ).filter_string
    # => "(&(objectClass=inetOrgPerson)(sn=Smith))"

We're experimenting with support for Sequel expressions for more-complex filter expressions, too:

    # Negative 
    irb> dir.ou( :people ).filter( ~:photo ).filter_string
    # => "(!(photo=*))"
    irb> dir.ou( :people ).filter( :employeeNumber <= 1000 ).filter_string
    # => "(employeeNumber<=1000)"
    irb> dir.ou( :people ).filter( :sn.like('smith') ).filter_string
    # => "(sn~=smith)"
    irb> dir.ou( :people ).filter( :sn.like('sm*') ).filter_string
    # => "(sn=sm*)"
    irb> dir.ou( :people ).filter( :sn => ['smith', 'tran'] ).filter_string
    # => "(|(sn=smith)(sn=tran))"


## Scope

You can also create a Branchset that will search using a different scope by
passing `:onelevel`, `:base`, or `:subtree` (the default) to the `#scope`
method of the original Branchset:

Setting the scope to `:onelevel` (as you might expect) means that it will only
descend one level when searching:

    irb> dir.filter( :objectClass => :organizationalUnit ).scope( :onelevel ).collect {|branch| branch[:ou].first }
    => ["Hosts", "Groups", "Lists", "Resources", "People", "Departments", "Netgroups"]

Setting it to `:subtree` (which is the default) means that it will descend
infinitely, and setting it to `:base` means that it will only consider the base
entry, either returning it if it matches, or returning `nil` if it does not.

There are also scope aliases; you can use `:one` instead of `:onelevel`, and
`:sub` instead of `:subtree`.

## Limit

Setting Treequel::Branchset#limit will limit the number of results the search will return.

    irb> dir.ou( :groups ).limit( 5 ).collect {|b| b.dn }
    # => ["ou=Groups,dc=acme,dc=com", "cn=anim,ou=Groups,dc=acme,dc=com", "cn=acct,ou=Groups,dc=acme,dc=com", "cn=mailuser,ou=Groups,dc=acme,dc=com", "cn=producer,ou=Groups,dc=acme,dc=com"]

**Note**: The results will be returned in _directory order_ (at least in
OpenLDAP). Until Treequel supports [server-side
ordering](http://tools.ietf.org/html/rfc2891), this means that `#limit` is of
limited usefulness; to do real paged results you need both server-side ordering
and [the paged results control](http://tools.ietf.org/html/rfc2696).

We're planning on adding a convenient way to use [controls](http://tools.ietf.org/html/rfc4511#page-14) in a future release.

If you already have a Branchset with a limit, and want a new one that won't have any limits imposed on it, you can get one via the Branchset#without_limit method.

    irb> fivegroups = dir.ou( :groups ).limit( 5 )
    # => #<Treequel::Branchset:0x1264908 base_dn='ou=groups,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=5, timeout=0.000>
    irb> fivegroups.all.length
    # => 5
    irb> fivegroups.without_limit.all.length
    # => 99

## Select

If you should want to limit the attributes that are returned in the entries
fetched by the query, you can do so by specifying which ones should be returned
with the Treequel::Branchset#select method:

    irb> dir.ou( :people ).select( :sn, :givenName ).limit( 5 ).collect {|b| b.entry }
    # => [{"dn"=>["ou=People,dc=acme,dc=com"]}, {"givenName"=>["Reed"], "sn"=>["Slimlocke"], "dn"=>["uid=rslim,ou=People,dc=acme,dc=com"]}, {"givenName"=>["Jim"], "sn"=>["Tran"], "dn"=>["uid=jtran,ou=People,dc=acme,dc=com"]}, {"givenName"=>["Michael"], "sn"=>["Granger"], "dn"=>["uid=mgranger,ou=People,dc=acme,dc=com"]}, {"givenName"=>["Harken"], "sn"=>["Farkselstein"], "dn"=>["uid=hfarkselstein,ou=People,dc=acme,dc=com"]}]

You can get a copy of a Branchset with additional attributes by passing the
additional attributes to Treequel::Branchset#select_more:

    irb> people_uids = dir.ou( :people ).select( :uid )
    # => #<Treequel::Branchset:0x1181644 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=uid, limit=0, timeout=0.000>
    irb> people_uids_and_names = people_uids.select_more( :gecos )
    # => #<Treequel::Branchset:0x1178b20 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=uid,gecos, limit=0, timeout=0.000>
    irb> people_uids_names_and_addresses = people_uids.select_more( :gecos, :homePostalAddress )
    # => #<Treequel::Branchset:0x10dcb08 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=uid,gecos,homePostalAddress, limit=0, timeout=0.000>

You can also get a copy with the select-list removed with Treequel::Branchset#select_all:

    irb> people_uids.select_all
    # => #<Treequel::Branchset:0x10da308 base_dn='ou=people,dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=0, timeout=0.000>


## Timeout

To avoid unintentional resource consumption on the server, you can specify an
explicit timeout for queries. This is useful when searching with user submitted
input or other untrusted sources. Note that this can only be reliably used to
_decrease_ the timeout, as the server might have a maximum timeout configured
that can't be exceeded.

    irb> dir.filter('objectClass=*').timeout( 1 ).all
    LDAP::ResultError: Timed out
    	from ./treequel/directory.rb:328:in `search_ext2'
    	from ./treequel/directory.rb:328:in `search'
    	from ./treequel/branchset.rb:195:in `each'
    	from (irb):8:in `all'
    	from (irb):8
    	from :0

If you have a canned query that includes a timeout, you can copy it without the
restriction.

    irb> slow_query = dir.filter('objectClass=*').timeout( 1 )
    # => #<Treequel::Branchset:0x1d5c554 base_dn='dc=acme,dc=com', filter=(objectClass=*), scope=subtree, select=*, limit=0, timeout=1.000>
    irb> slow_query.all
    LDAP::ResultError: Timed out
    	from ./treequel/directory.rb:328:in `search_ext2'
    	from ./treequel/directory.rb:328:in `search'
    	from ./treequel/branchset.rb:195:in `each'
    	from (irb):13:in `all'
    	from (irb):13
    	from :0
    irb> slow_query.without_timeout.all.length
    # => 4982
    irb> slow_query.without_timeout.all.first
    # => #<Treequel::Branch:0x1d4f2f0 dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry={"o"=>["ACME"], "description"=>["http://www.example.com/"], "objectClass"=>["dcObject", "organization"], "dc"=>["acme"], "dn"=>["dc=acme,dc=com"]}>


### Branchset Enumeration

Branchsets are also `Enumerable`, so you can slice and dice results with its
interface:

    irb> people = dir.ou( :people )
    # => #<Treequel::Branch:0x11857d0 ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
    irb> people.all? {|person| File.directory?(person[:homeDirectory]) }
    NoMethodError: undefined method `all?' for #<Treequel::Branch:0x11857d0>
    	from /Users/mgranger/source/ruby/Treequel/lib/treequel/branch.rb:538:in `method_missing'
    	from (irb):3
    irb> people.filter( :homeDirectory ).all? {|person| File.directory?(person[:homeDirectory]) }
    # => false
    irb> people.filter( :homeDirectory ).find_all {|person| File.exist?(person[:homeDirectory]) && File.stat(person[:homeDirectory]).uid != person[:uidNumber] }
    # => [#<Treequel::Branch:0x18287b8 uid=wwwspider,ou=People,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry={"cn"=>["Auth account for web spider"], "gidNumber"=>["200"], "givenName"=>["WebSpider"], "gecos"=>["WebSpider Account"], "homeDirectory"=>["/dev/null"], "sn"=>["WebSpider Account"], "uid"=>["wwwspider"], "uidNumber"=>["1500"], "objectClass"=>["top", "person", "inetOrgPerson", "posixAccount", "shadowAccount"], "dn"=>["uid=wwwspider,ou=People,dc=acme,dc=com"]}>]

For convenience, the Treequel::Branchset#map method is overridden to facilitate
fetching single attributes from the resulting branches:

    irb> dir.ou( :hosts ).filter( :ipHostNumber ).map( :ipHostNumber ).flatten
    => ["192.168.1.253", "192.168.1.14", "192.168.1.21", "192.168.1.22", "192.168.1.23"]




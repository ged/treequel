# Real-World \Examples

## Cross-directory Searches

For example, this one-liner finds the first name of all `inetOrgPerson`
classes within the `People` organizational unit that have a `uid` that
starts with the string "ma":

```ruby
irb> dir.ou( :people ).filter( :objectClass => 'inetOrgPerson' ).filter( :uid => 'ma*' ).collect {|branch| branch[:givenName].first }.sort
# => ["Mahlon", "Margaret", "Margaret", "Mark", "Marlon", "Matt", "Mike", "Mimi"]
```


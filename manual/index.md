# Treequel Manual

This is a manual for *Treequel*, a Ruby library that is intended to make
interacting with an LDAP directory natural and easy without trying to make it
behave like a relational database. It's built on top of
[Ruby-LDAP](http://ruby-ldap.sourceforge.net/), so if you don't already have
that installed you'll need to install it (`gem install ruby-ldap`
should work for modern versions of Ruby), and you'll need to have access to an
LDAP server, of course.

1. [Connecting to a Directory](Connecting_md.html)
1. [Binding to a Directory](Binding_md.html)
1. [Working With Branches](Branches_md.html)
1. [Searching With Branchsets](Branchsets_md.html)
1. [Branch Collections](BranchCollections_md.html)
1. [Models](Models_md.html)
1. [Schema Introspection](Schema_md.html)
1. [Real-World Examples](Examples_md.html)


## Authors

* Michael Granger <ged@FaerieMUD.org>
* Mahlon E. Smith <mahlon@martini.nu>


## Contributors

A special thanks to Ben Bleything, who was part of the initial brainstorm that
led to the creation of this library.


## License

Copyright © 2008-2017, Michael Granger and Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the authors nor contributors may be used to endorse or
  promote products derived from this software without specific prior written
  permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

<div id="cc-license">
The content of this manual, including images, video, and any example source
code is licensed under a <a rel="license"
href="http://creativecommons.org/licenses/by/3.0/">Creative Commons Attribution
3.0 License</a>.
</div>

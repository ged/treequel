# Treequel - an honest LDAP library

* http://deveiate.org/projects/Treequel

## Description

Treequel is an LDAP toolkit for Ruby. It is intended to allow quick, easy
access to LDAP directories in a manner consistent with LDAP's hierarchical,
free-form nature. 

It's inspired by and modeled after [Sequel](http://sequel.rubyforge.org/), a
kick-ass database library.


## Examples

Here are a few short examples to whet your appetite:

    # Connect to the directory at the specified URL
    dir = Treequel.directory( 'ldap://ldap.company.com/dc=company,dc=com' )
    
    # Get a list of email addresses of every person in the directory (as
    # long as people are under ou=people)
    dir.ou( :people ).filter( :mail ).map( :mail ).flatten
    
    # Get a list of all IP addresses for all hosts in any ou=hosts group
    # in the whole directory:
    dir.filter( :ou => :hosts ).collection.filter( :ipHostNumber ).
      map( :ipHostNumber ).flatten
    
    # Get all people in the directory in the form of a hash of names 
    # keyed by email addresses
    dir.ou( :people ).filter( :mail ).to_hash( :mail, :cn )

More elaborate examples of real-world usage can be found 
[in the examples/ directory][examples] in the distribution.


## Contributing

You can check out the current development source [with Mercurial][hgrepo], or
if you prefer Git, via the project's [Github mirror][gitmirror].

You can submit bug reports, suggestions, and read more about future plans at
[the project page][projectpage].


## License

Copyright (c) 2008-2011, Michael Granger and Mahlon E. Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software includes some code from the Sequel database toolkit, used under 
the following license terms:

  Copyright (c) 2007-2008 Sharon Rosner
  Copyright (c) 2008-2010 Jeremy Evans
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
    
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
     
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  

## Authors

* Michael Granger <ged@FaerieMUD.org>
* Mahlon E. Smith <mahlon@martini.nu>


## Contributors

A special thanks to Ben Bleything, who was part of the initial brainstorm that
led to the creation of this library.

Thanks also to Ben Cooksley of the KDE project, who has been full of great 
ideas for the Model side of Treequel; it's vastly better for his
suggestions.


[examples]:http://deveiate.org/projects/Treequel/browser/examples
[hgrepo]:http://repo.deveiate.org/Treequel
[gitmirror]:https://github.com/ged/treequel
[projectpage]:http://deveiate.org/projects/Treequel


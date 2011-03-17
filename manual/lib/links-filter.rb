#!/usr/bin/ruby 
# 
# A manual filter to generate links from the page catalog.
# 
# Authors:
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
# 
# 


### A filter for generating links from the page catalog. This allows you to refer to other pages
### in the source and have them automatically updated as the structure of the manual changes.
### 
### Links are XML processing instructions. Pages can be referenced in one of several ways:
###
###   <?link Page Title ?>
###   <?link "click here":Page Title ?>
###   <?link Page Title #section_id ?>
###   <?link "click here":Page Title#section_id ?>
### 
### This first form links to a page by title. Link text defaults to the page title unless an 
### optional quoted string is prepended. If you want to link to an anchor inside the page, include
### its ID with a hash mark after the title.
###
###   <?link path/to/Catalog.page ?>
###   <?link "click here":path/to/Catalog.page ?>
###   <?link path/to/Catalog.page#section_id ?>
###   <?link "click here":path/to/Catalog.page#section_id ?>
###
### The second form links to a page by its path relative to the base manual source directory.
### Again, the link text defaults to the page title, or can be overriden via a prepended string,
### and you can link into a page with an appended ID.
class Hoe::ManualGen::LinksFilter < Hoe::ManualGen::PageFilter
	
	# PI	   ::= '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
	LinkPI = %r{
		<\?
			link				# Instruction Target
			\s+
			(?:"					
				(.*?)           # Optional link text [$1]
			":)?
			(.*?)				# Title or path [$2]
			\s*
			(\#\w+)?				# Fragment [$3]
			\s+
		\?>
	  }x
	
	
	######
	public
	######

	### Process the given +source+ for <?link ... ?> processing-instructions, calling out
	def process( source, page, metadata )
		return source.gsub( LinkPI ) do |match|
			# Grab the tag values
			link_text = $1
			reference = $2
			fragment  = $3
			
			self.generate_link( page, reference, link_text, fragment )
		end
	end
	
	
	### Create an HTML link fragment from the parsed LinkPI.
	def generate_link( current_page, reference, link_text=nil, fragment=nil )

		if other_page = self.find_linked_page( current_page, reference )
			href_path = other_page.sourcefile.relative_path_from( current_page.sourcefile.dirname )
			href = href_path.to_s.gsub( '.page', '.html' )
		
			if link_text
				return %{<a href="#{href}#{fragment}">#{link_text}</a>}
			else
				return %{<a href="#{href}#{fragment}">#{other_page.title}</a>}
			end
		else
			link_text ||= reference
			error_message = "Could not find a link for reference '%s'" % [ reference ]
			$stderr.puts( error_message )
			return %{<a href="#" title="#{error_message}" class="broken-link">#{link_text}</a>}
		end
	end
	
	
	### Lookup a page +reference+ in the catalog.  +reference+ can be either a
	### path to the .page file, relative to the manual root path, or a page title.
	### Returns a matching Page object, or nil if no match is found.
	def find_linked_page( current_page, reference )
		
		catalog = current_page.catalog
		
		# Lookup by page path
		if reference =~ /\.page$/
			return catalog.uri_index[ reference ]
			
		# Lookup by page title
		else
			return catalog.title_index[ reference ]
		end
	end
end






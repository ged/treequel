#!/usr/bin/ruby 
# 
# A manual filter to highlight content that needs editorial help.
# 
# Authors:
# * Michael Granger <ged@FaerieMUD.org>
# 
# 



### A filter for making editorial marks in manual content.
### 
### Editorial marks are XML processing instructions. There are several available types of
### marks:
###
###   <?ed "This is an editor's note." ?>
###   <?ed verify:"this content needs checking or verification" ?>
### 
class Hoe::ManualGen::EditorialFilter < Hoe::ManualGen::PageFilter
	
	# PI	   ::= '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
	LinkPI = %r{
		<\?
			ed					# Instruction Target
			\s+
			(\w+?)				# type of editorial mark [$1]
			:?					# optional colon
			"					
				(.*?)           # content that should be edited [$2]
			"
			\s*
		\?>
	  }x
	
	
	######
	public
	######

	### Process the given +source+ for <?ed ... ?> processing-instructions
	def process( source, page, metadata )
		return source.gsub( LinkPI ) do |match|
			# Grab the tag values
			mark_type = $1
			content   = $2
			
			self.generate_mark( page, mark_type, content )
		end
	end
	
	
	### Create an HTML fragment from the parsed LinkPI.
	def generate_mark( current_page, mark_type, content )
		return "%%(editorial %s-mark)%s%%" % [ mark_type, content ]
	end
	
	
end

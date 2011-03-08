#!/usr/bin/env ruby
#encoding: utf-8

require 'treequel/model'


# A collection of schema-based validations for LDAP model objects.
module Treequel::Model::SchemaValidations

	# OpenLDAP servers with syncrepl include 'entryCSN' and 'contextCSN' attributes, but
	# don't define its attribute type in the subschema. This is a list of operational
	# attribute types that don't appear in the subschema that shouldn't be considered when 
	# validating MUST and MAY attributes. 
	# (http://www.openldap.org/its/index.cgi/Development?id=5573)
	IGNORED_OPERATIONAL_ATTRS = [ :entryCSN, :contextCSN ]


	### Entrypoint -- run all the validations, adding any errors to the
	### object's #error collector.
	def validate( options={} )
		return unless options[:with_schema]

		self.validate_structural_objectclass
		self.validate_must_attributes
		self.validate_may_attributes
		self.validate_attribute_syntax
	end


	### Ensure that the object has at least one structural objectClass.
	def validate_structural_objectclass
		unless self.object_classes.any? {|oc| oc.structural? }
			self.errors.add( :entry, "must have at least one structural objectClass" )
		end
	end


	### Validate that all attributes that MUST be included according to the entry's
	### objectClasses have at least one value.
	def validate_must_attributes
		self.must_attribute_types.each do |attrtype|
			oid = attrtype.name
			if attrtype.single?
				self.errors.add( oid, "MUST have a value" ) unless self[ oid ]
			else
				self.errors.add( oid, "MUST have at least one value" ) if self[ oid ].empty?
			end
		end
	end


	### Validate that all attributes present in the entry are allowed by either a
	### MUST or a MAY rule of one of its objectClasses.
	def validate_may_attributes
		hash = (self.entry || {} ).merge( @values )
		attributes = hash.keys.map( &:to_sym ).uniq
		valid_attributes = self.valid_attribute_oids +
			self.operational_attribute_oids +
			IGNORED_OPERATIONAL_ATTRS

		self.log.debug "Validating MAY attributes: %p against the list of valid OIDs: %p" %
			[ attributes, valid_attributes ]
		unknown_attributes = attributes - valid_attributes
		unknown_attributes.each do |oid|
			self.errors.add( oid, "is not allowed by entry's objectClasses" )
		end
	end


	### Validate that the attribute values present in the entry are all valid according to
	### the syntax rule for it.
	def validate_attribute_syntax
		@values.each do |attribute, values|
			[ values ].flatten.each do |value|
				begin
					self.get_converted_attribute( attribute.to_sym, value )
				rescue => err
					self.log.error "validation for %p failed: %s: %s" %
						[ attribute, err.class.name, err.message ]
					attrtype = self.find_attribute_type( attribute )
					self.errors.add( attribute, "isn't a valid %s value" %
					 	[ attrtype.syntax ? attrtype.syntax.desc : attrtype.syntax_oid ] )
				end
			end
		end
	end

end # module Treequel::Model::SchemaValidations


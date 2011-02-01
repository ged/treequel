## 1.4.0 [2011-01-31] Michael Granger <ged@FaerieMUD.org>

Enhancements:

* Added a new method: Treequel::Directory#connected?
* Adding reconnect support to the treequel shell

Bugfixes:

* Fixed a bug in Treequel::Branch#copy.
* Escape filter metacharacters in simple filter components


## 1.3.2

Bugfix:

* Ensure the entry hash that's passed to Treequel::Model#apply_applicable_mixins isn't modified; fixes a bug when modifying a new unsaved Model object.


## 1.3.1 [2011-01-17] Michael Granger <ged@FaerieMUD.org>

Fixed a bug that caused DN attributes in objects created via Treequel::Model.new_from_entry to be doubled.


## 1.3.0 [2011-01-13] Michael Granger <ged@FaerieMUD.org>

Enhancements:

* Made Treequel::Model act more like an ORM -- changes made to the object aren't synced
  with the directory until #save is called. New methods:
  - Treequel::Model#save
  - Treequel::Model#modifications
  - Treequel::Model#modifications_ldif
  - Treequel::Model#validate
  - Treequel::Model#valid?
  - Treequel::Model#errors
  - Treequel::Model#revert
  - Treequel::Model#modified?
  - Treequel::Model#after_initialize
  - Treequel::Model#before_validation
  - Treequel::Model#after_validation
  - Treequel::Model#before_save
  - Treequel::Model#before_create
  - Treequel::Model#before_update
  - Treequel::Model#after_create
  - Treequel::Model#after_update
  - Treequel::Model#after_save
  - Treequel::Model#before_destroy
  - Treequel::Model#after_destroy
  New classes:
  - Treequel::Model::Errors
  - Treequel::ValidationFailed
* Extracted the controls behavior and rewrote the control specs to use it. This is
  so people who may wish to implement their own controls can ensure that it's
  compatible with Treequel.
* Added a directory-introspection tool (treewhat)
* Added Treequel::Model::ObjectClass.create for easy creation of entries that conform
  to an objectClass mixin's criteria
* Treequel::Directory.root_dse now returns Treequel::Branches
* Added Treequel::Directory#reconnect.

Bugfixes:

* Fixed a bug in Treequel::Branch#merge for values that need conversion
* Simplified and removed duplication from the logging code
* Fixed a bug in the proxy method for single-letter attribute names.
* Monkeypatched Date for LDAP time type conversions
* Change the return values of unset attributes to distinguish between SINGLE and non-SINGLE 
  attributes
* Treequel::Branch
  - Check for explicit nil DN in .new
  - Check for nil parent_dn in #parent
  - Use 'top' instead of :top as objectClass default
  - Don't cache attempts to fetch invalid attributes


## 1.2.2 [2010-12-14] Michael Granger <ged@FaerieMUD.org>

Bugfixes for Treequel::Branch, Treequel::Model.


## 1.2.1 [2010-12-13] Michael Granger <ged@FaerieMUD.org>

Converted to Hoe.

Bugfix: objectClasses listed in Treequel::Model::ObjectClass.model_objectclasses can be Strings, too.


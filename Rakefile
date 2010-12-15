#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :hg
Hoe.plugin :yard
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.name = 'treequel'
	self.readme_file = 'README.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	self.extra_deps <<
		['ruby-ldap', '~> 0.9.11']
	self.extra_dev_deps <<
		['rspec', '~> 2.1.0'] <<
		['ruby-termios', '~> 0.9.6'] <<
		['ruby-terminfo', '~> 0.1.1'] <<
		['yard', '~> 0.6.1']

	self.spec_extras[:licenses] = ["BSD"]
	self.spec_extras[:post_install_message] = [
			"If you want to use the included 'treequel' LDAP shell, you'll need to install",
			"the following libraries as well:",
			"    - termios",
			"    - ruby-terminfo",
			"    - columnize",
		  ].join( "\n" )
    self.spec_extras[:signing_key] = '/Volumes/Keys/ged-private_gem_key.pem'

	self.require_ruby_version( '>=1.8.7' )
	self.hg_sign_tags = true
	self.yard_opts = [ '--use-cache', '--protected', '--verbose' ]
	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

include Hoe::MercurialHelpers


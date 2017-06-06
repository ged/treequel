#!/usr/bin/env ruby

require 'rspec'

require 'treequel'
require 'treequel/control'


# This is a shared behavior for specs which different Treequel::Controls share in 
# common. If you're creating a Treequel::Control implementation, you can test
# its conformity to the expectations placed on them by adding this to your spec:
# 
#    require 'treequel/behavior/control'
#
#    describe YourControl do
#
#      it_should_behave_like "A Treequel::Control"
#
#    end

RSpec.shared_examples_for "A Treequel::Control" do

	let( :control ) do
		described_class
	end


	it "implements one of either #get_client_controls or #get_server_controls" do
		methods = [
			:get_client_controls,
			:get_server_controls
		]
		expect( control.instance_methods(false) | methods ).to_not be_empty()
	end

end



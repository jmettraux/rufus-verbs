
#
# spec'ing rufus-verbs
#
# Wed Jul 31 20:54:36 JST 2013
#

require 'spec_helper'


describe Rufus::Verbs do

  context ':no_escape => (nothing)' do

    it 'escapes by default' do

      req = Rufus::Verbs.put(
        :dry_run => true,
        :uri => 'http://localhost:7777/items/1',
        :query => { 'a' => 'hontou ni ?' })

      req.path.should == "/items/1?a=hontou%20ni%20?"
    end
  end

  context ':no_escape => true' do

    it 'disables escaping' do

      req = Rufus::Verbs.put(
        :dry_run => true,
        :uri => 'http://localhost:7777/items/1',
        :query => { 'a' => 'hontou ni ?' },
        :no_escape => true)

      req.path.should == "/items/1?a=hontou ni ?"
    end
  end

  context ':escape => false' do

    it 'disables escaping'
  end
end


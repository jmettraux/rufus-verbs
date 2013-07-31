
require File.dirname(__FILE__) + '/base.rb'


class MergeTest < Test::Unit::TestCase

  include Rufus::Verbs


  def test_0

    ep = EndPoint.new(
      :dry_run => true,
      :uri => 'http://host/path',
      :params => { 'token' => 'apiaccess'})

    req = ep.get(
      :params => { 'extra' => 'param'})

    assert_equal "/path?token=apiaccess&extra=param", req.path

  end
end

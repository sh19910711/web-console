require 'test_helper'

module WebConsole
  class ContextTest < ActiveSupport::TestCase
    test '#of(empty) includes local variables' do
      local_var = 'local'
      assert Context.new(binding).of('').include?(:local_var)
    end

    test '#of(empty) includes instance variables' do
      @instance_var = 'instance'
      assert Context.new(binding).of('').include?(:@instance_var)
    end

    test '#of(empty) includes global variables' do
      $global_var = 'global'
      assert Context.new(binding).of('').include?(:$global_var)
    end

    test '#of(obj) returns methods' do
      assert Context.new(binding).of('Rails').include?('Rails.root')
    end

    test '#of(obj) returns constants' do
      assert Context.new(binding).of('WebConsole').include?('WebConsole::Middleware')
    end
  end
end

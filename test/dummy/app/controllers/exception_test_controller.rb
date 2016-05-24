class ExceptionTestController < ApplicationController
  def index
    test = "Test"
    test_method
  end

  def xhr
    raise "asda" if request.xhr?
  end

  def test_method
    test2 = "Test2"
    WebConsole.raise_not_found
    raise StandardError
  end
end

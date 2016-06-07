class AnywhereTestController < ApplicationController
  def index
    test1 = 'foo'
  end

  def xhr_console
    test2 = 'bar'
    console
    render json: {}
  end
end

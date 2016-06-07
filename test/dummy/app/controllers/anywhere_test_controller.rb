class AnywhereTestController < ApplicationController
  def view_console
    test1 = 'foo'
    render :console
  end

  def xhr_console
    test2 = 'bar'
    console
    render json: {}
  end
end

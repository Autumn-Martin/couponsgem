class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :something

  def something
    binding.pry
  end
end

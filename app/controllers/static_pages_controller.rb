class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :top, :how_to_use, :terms, :privacy ]
  def top; end

  def how_to_use; end

  def terms; end

  def privacy; end
end

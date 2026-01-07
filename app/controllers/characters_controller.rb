class CharactersController < ApplicationController
  def index
    @characters = current_user.characters.order(created_at: :desc).page(params[:page])
  end

  def new
    @character = Character.new
  end

  def create
    #
  end
end

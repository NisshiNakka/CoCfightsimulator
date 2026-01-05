class CharactersController < ApplicationController
  def index
    @characters = current_user.characters.order(created_at: :desc).page(params[:page])
  end
end

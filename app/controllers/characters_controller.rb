class CharactersController < ApplicationController
  def index
    @characters = current_user.characters.order(created_at: :desc)
  end
end

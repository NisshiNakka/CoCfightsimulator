class CharactersController < ApplicationController
  def index
    @characters = current_user.characters.order(created_at: :desc).page(params[:page])
  end

  def new
    @character = Character.new
  end

  def create
    @character = current_user.characters.build(character_params)
    if @character.save
      redirect_to characters_path, success: t("defaults.flash_message.created", item: Character.model_name.human)
    else
      flash.now[:danger] = t("defaults.flash_message.not_created", item: Character.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def character_params
    params.require(:character).permit(:name, :hitpoint, :dexterity, :evasion_rate, :evasion_correction, :armor, :damage_bonus)
  end
end

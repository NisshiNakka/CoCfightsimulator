class CharactersController < ApplicationController
  def index
    @characters = current_user.characters.order(created_at: :desc).page(params[:page])
  end

  def new
    @character = Character.new
    @character.attacks.build
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

  def show
    @character = current_user.characters.find(params[:id])
  end

  def edit
    @character = current_user.characters.find(params[:id])
    @character.attacks.build if @character.attacks.blank?
  end

  def update
    @character = current_user.characters.find(params[:id])
    if @character.update(character_params)
      redirect_to character_path(@character), success: t("defaults.flash_message.updated", item: Character.model_name.human)
    else
      flash.now[:danger] = t("defaults.flash_message.not_updated", item: Character.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    character = current_user.characters.find(params[:id])
    character.destroy!
    redirect_to characters_path, success: t("defaults.flash_message.deleted", item: Character.model_name.human), status: :see_other
  end

  private

  # def set_character
  #   @character = current_user.characters.find(params[:id])
  # end

  def character_params
    params.require(:character).permit(:name, :hitpoint, :dexterity, :evasion_rate, :evasion_correction, :armor, :damage_bonus,
    attacks_attributes: [
        :id,
        :name,
        :success_probability,
        :dice_correction,
        :damage,
        :attack_range,
        :_destroy
      ]
    )
  end
end

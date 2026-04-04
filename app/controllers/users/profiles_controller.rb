class Users::ProfilesController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: t("defaults.flash_message.updated", item: t("users.profiles.show.dice_collection"))
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:site_icon)
  end
end

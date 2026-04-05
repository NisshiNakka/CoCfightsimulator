class Users::ProfilesController < ApplicationController
  def show
    @user = current_user
    grant_tickets(:profile_view)
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      current_user.increment!(:dice_updates_count)
      grant_tickets(:dice_update)
      redirect_to profile_path, notice: t("defaults.flash_message.updated", item: t("users.profiles.show.dice_collection"))
    else
      render :show, status: :unprocessable_entity
    end
  end

  def use_ticket
    unlocked_key = current_user.use_ticket!
    @unlocked_key = unlocked_key
    @all_collected = current_user.all_dice_collected?

    respond_to do |format|
      format.turbo_stream
    end
  rescue User::InsufficientTicketsError
    redirect_to profile_path, alert: t("users.profiles.use_ticket.insufficient_tickets")
  rescue User::AllDiceCollectedError
    redirect_to profile_path, alert: t("users.profiles.use_ticket.all_collected")
  end

  private

  def profile_params
    params.require(:user).permit(:site_icon)
  end
end

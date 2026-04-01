class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      is_new_user = @user.previously_new_record?
      @user.update!(tutorial_step: 1) if is_new_user
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: "Google")
      sign_in @user, event: :authentication
      redirect_to is_new_user ? new_character_path : root_path
    else
      session["devise.google_oauth2_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: I18n.t("devise.omniauth_callbacks.failure",
                                          kind: "Google",
                                          reason: failure_message)
  end
end

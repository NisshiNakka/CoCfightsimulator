class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    resource.update!(tutorial_step: 1)
    new_character_path
  end
end

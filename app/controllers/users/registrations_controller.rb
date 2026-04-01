class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    resource.update!(tutorial_step: 1)
    new_character_path
  end

  def update_resource(resource, params)
    if resource.provider.present?
      resource.update_without_current_password(params)
    else
      super
    end
  end
end

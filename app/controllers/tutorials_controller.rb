class TutorialsController < ApplicationController
  def update
    case params[:action_type]
    when "advance"
      current_user.advance_tutorial!
    when "dismiss"
      current_user.dismiss_tutorial!
    end
    head :ok
  end
end

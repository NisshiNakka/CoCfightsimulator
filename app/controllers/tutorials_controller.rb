class TutorialsController < ApplicationController
  def update
    case params[:action_type]
    when "advance"
      current_user.advance_tutorial!
    when "dismiss"
      current_user.dismiss_tutorial!
    when "start_collection"
      current_user.start_collection_tutorial!
    when "advance_collection"
      current_user.advance_collection_tutorial!
    when "dismiss_collection"
      current_user.dismiss_collection_tutorial!
    end
    head :ok
  end
end

require "bcdice"

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  add_flash_types :success, :danger

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :email ])
    # ↓ MVPリリースまでの仮設定　できればdeviseのconfirmableモジュールを有効化するか、emailを使用しないユーザー認証に変える(万一アカウント乗っ取りがあっても、当アプリでしか使用しない情報しか渡さない)
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :email ])
  end

  # 特典券付与 + チュートリアル中でなければ通知フラグをセット
  def grant_tickets(action)
    return [] if current_user.any_tutorial_active?

    granted = RewardTicketGranter.call(current_user, action: action)
    flash[:reward_ticket_granted] = granted.size if granted.any?
    granted
  end
end

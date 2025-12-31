require "bcdice"

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :email ])
    # ↓ MVPリリースまでの仮設定　できればdeviseのconfirmableモジュールを有効化するか、emailを使用しないユーザー認証に変える(万一アカウント乗っ取りがあっても、当アプリでしか使用しない情報しか渡さない)
    devise_parameter_sanitizer.permit(:account_update, keys: [ :email ])
  end
end

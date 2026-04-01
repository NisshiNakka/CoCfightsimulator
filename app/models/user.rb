class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  validates :name, presence: true, length: { maximum: 50 }

  has_many :characters, dependent: :destroy

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid) # uidで既存OAuthユーザーを検索
    return user if user

    user = find_by(email: auth.info.email) # メールアドレスで作成した既存ユーザーを検索
    if user
      user.update!(provider: auth.provider, uid: auth.uid) # 既存ユーザーにOAuth情報を追加
      return user
    end

    # いずれも見つからない場合は新規ユーザーを作成
    create(
      email: auth.info.email,
      provider: auth.provider,
      uid: auth.uid,
      password: Devise.friendly_token[0, 20],
      name: auth.info.name || auth.info.email.split("@").first
    )
  end

  def password_required?
    provider.blank? && super
  end

  def update_without_current_password(params)
    params.delete(:password) if params[:password].blank?
    params.delete(:password_confirmation) if params[:password_confirmation].blank?
    update(params)
  end

  TUTORIAL_LAST_STEP = 6

  def tutorial_active?
    tutorial_step > 0
  end

  def advance_tutorial!
    next_step = tutorial_step + 1
    update!(tutorial_step: next_step <= TUTORIAL_LAST_STEP ? next_step : 0)
  end

  def dismiss_tutorial!
    update!(tutorial_step: 0)
  end
end

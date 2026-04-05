class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # 常時選択可能な特殊アイコン
  SPECIAL_ICONS = %w[defaults none].freeze

  # コレクション対象のダイス（22種）
  COLLECTABLE_DICE_KEYS = %w[
    cat/cat_azuki_webp cat/cat_mike_webp cat/cat_pink_webp
    color/black color/blue color/red
    cthulhu/cthulhu_webp cthulhu/cthulhu_b_webp
    kirakira/cosmos_webp kirakira/crystal_webp kirakira/cyber_webp kirakira/magic_webp
    pop/berry_webp pop/caramel_webp pop/heart_webp pop/kids_webp pop/star_webp
    roll/kuru_r
    simple/note_webp
    wafu/horror_webp wafu/kanji_webp wafu/miyabi_webp
  ].freeze

  MAX_TICKETS = COLLECTABLE_DICE_KEYS.size

  # ダイスの表示名
  DICE_DISPLAY_NAMES = {
    "defaults" => "デフォルト",
    "none" => "非表示",
    "cat/cat_azuki_webp" => "ネコ（あずき）",
    "cat/cat_mike_webp" => "ネコ（みけ）",
    "cat/cat_pink_webp" => "ネコ（ピンク）",
    "color/black" => "カラー（黒）",
    "color/blue" => "カラー（青）",
    "color/red" => "カラー（赤）",
    "cthulhu/cthulhu_webp" => "クトゥルフ",
    "cthulhu/cthulhu_b_webp" => "クトゥルフ（黒）",
    "kirakira/cosmos_webp" => "きらきら（コスモス）",
    "kirakira/crystal_webp" => "きらきら（クリスタル）",
    "kirakira/cyber_webp" => "きらきら（サイバー）",
    "kirakira/magic_webp" => "きらきら（マジック）",
    "pop/berry_webp" => "ポップ（ベリー）",
    "pop/caramel_webp" => "ポップ（キャラメル）",
    "pop/heart_webp" => "ポップ（ハート）",
    "pop/kids_webp" => "ポップ（キッズ）",
    "pop/star_webp" => "ポップ（スター）",
    "roll/kuru_r" => "ロール",
    "simple/note_webp" => "シンプル（ノート）",
    "wafu/horror_webp" => "和風（ホラー）",
    "wafu/kanji_webp" => "和風（漢字）",
    "wafu/miyabi_webp" => "和風（みやび）"
  }.freeze

  validates :name, presence: true, length: { maximum: 50 }
  validates :site_icon, inclusion: { in: ->(user) { user.available_site_icons } }

  has_many :characters, dependent: :destroy
  has_many :dice_unlocks, class_name: "UserDiceUnlock", dependent: :destroy
  has_many :reward_milestones, class_name: "UserRewardMilestone", dependent: :destroy

  after_create -> { RewardTicketGranter.call(self, action: :registration) }

  class InsufficientTicketsError < StandardError; end
  class AllDiceCollectedError < StandardError; end

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
  COLLECTION_TUTORIAL_LAST_STEP = 2

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

  def collection_tutorial_active?
    collection_tutorial_step > 0
  end

  def any_tutorial_active?
    tutorial_active? || collection_tutorial_active?
  end

  def start_collection_tutorial!
    update!(collection_tutorial_step: 1)
  end

  def advance_collection_tutorial!
    next_step = collection_tutorial_step + 1
    update!(collection_tutorial_step: next_step <= COLLECTION_TUTORIAL_LAST_STEP ? next_step : 0)
  end

  def dismiss_collection_tutorial!
    update!(collection_tutorial_step: 0)
  end

  def site_icon_path
    case site_icon
    when "defaults"
      "all_dice/logo_defaults.webp"
    when "none"
      nil
    when *COLLECTABLE_DICE_KEYS
      "all_dice/#{site_icon}.webp"
    else
      "all_dice/logo_defaults.webp"
    end
  end

  # ===== ダイスコレクション関連 =====

  def unlocked_dice_keys
    dice_unlocks.pluck(:dice_key)
  end

  def available_site_icons
    SPECIAL_ICONS + unlocked_dice_keys
  end

  def dice_unlocked?(dice_key)
    dice_unlocks.exists?(dice_key: dice_key)
  end

  def all_dice_collected?
    dice_unlocks.count >= COLLECTABLE_DICE_KEYS.size
  end

  def use_ticket!
    with_lock do
      raise InsufficientTicketsError if reward_tickets <= 0
      raise AllDiceCollectedError if all_dice_collected?

      locked_dice = COLLECTABLE_DICE_KEYS - unlocked_dice_keys
      selected = locked_dice.sample

      decrement!(:reward_tickets)
      dice_unlocks.create!(dice_key: selected)
      selected
    end
  end
end

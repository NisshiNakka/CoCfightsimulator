class Character < ApplicationRecord
  include DiceRollable

  paginates_per 20

  has_one_attached :icon

  validates :name, presence: true, length: { maximum: 50 }
  validates :hitpoint, presence: true, numericality: { only_integer: true, in: 3..100 }
  validates :dexterity, presence: true, numericality: { only_integer: true, in: 1..200 }
  validates :evasion_rate, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :evasion_correction, presence: true, numericality: { only_integer: true, in: -10..10 }
  validates :armor, presence: true, numericality: { only_integer: true, in: 0..20 }
  validates :damage_bonus, presence: true, length: { maximum: 15 }, format: {
    with: /\A-?\d+(?:[dD]\d+)?(?:[+\-]\d+(?:[dD]\d+)?)*\z/,
    message: "は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）"
  }

  validate :icon_content_type_validation
  validate :icon_size_validation

  belongs_to :user
  has_one :attack, dependent: :destroy
  accepts_nested_attributes_for :attack,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :attack, presence: true

  def evasion_roll(correction)
    dice_system.eval("CC#{evasion_correction}<=#{evasion_rate}#{correction}")
  end

  def hp_calculation(damage_result, progress_hp)
    damage_value = damage_result.text.split(" ＞ ").last.to_i
    effective_damage = [ 0, damage_value - armor ].max
    remaining_hp = progress_hp - effective_damage
    {
      hp: remaining_hp,
      damage: effective_damage
    }
  end

  # セッションのHPの値と同一
  attr_accessor :current_hp

  def fall_down?
    current_hp <= 2
  end

  def health_status
    return :death if death?
    return :fainting if fall_down?
    :healthy
  end

  private

  def icon_content_type_validation
    return unless icon.attached?

    unless icon.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:icon, :invalid_content_type)
    end
  end

  def icon_size_validation
    return unless icon.attached?

    errors.add(:icon, :too_large) if icon.blob.byte_size > 5.megabytes
  end

  def death?
    current_hp <= 0
  end
end

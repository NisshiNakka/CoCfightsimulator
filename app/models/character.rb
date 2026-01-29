class Character < ApplicationRecord
  include DiceRollable

  paginates_per 20

  validates :name, presence: true, length: { maximum: 50 }
  validates :hitpoint, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :dexterity, presence: true, numericality: { only_integer: true, in: 1..200 }
  validates :evasion_rate, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :evasion_correction, presence: true, numericality: { only_integer: true, in: -10..10 }
  validates :armor, presence: true, numericality: { only_integer: true, in: 0..20 }
  validates :damage_bonus, presence: true, length: { maximum: 15 }, format: {
    with: /\A-?\d+(?:[dD]\d+)?(?:[+\-]\d+(?:[dD]\d+)?)*\z/,
    message: "は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）"
  }

  belongs_to :user
  has_many :attacks, dependent: :destroy
  accepts_nested_attributes_for :attacks,
                                allow_destroy: true,
                                reject_if: :all_blank

  validate :attacks_count_range

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
    current_hp <= 0
  end

  private

  def attacks_count_range
    valid_attacks = attacks.reject(&:marked_for_destruction?)

    if valid_attacks.empty?
      errors.add(:base, "攻撃技能を最低1つ登録してください")
    elsif valid_attacks.size > 3
      errors.add(:base, "攻撃技能は3つまでしか登録できません")
    end
  end
end

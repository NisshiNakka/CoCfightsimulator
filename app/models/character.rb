class Character < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :hitpoint, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :dexterity, presence: true, numericality: { only_integer: true, in: 1..200 }
  validates :evasion_rate, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :evasion_correction, presence: true, numericality: { only_integer: true, in: -10..10 }
  validates :armor, presence: true, numericality: { only_integer: true, in: 0..20 }
  validates :damage_bonus, presence: true, length: { maximum: 15 }, format: {
    with: /\A-?\d+(?:[dD]\d+(?:[+\-]\d+)?)?\z/,
    message: "は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）"
  }

  belongs_to :user
end

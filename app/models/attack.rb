class Attack < ApplicationRecord
  validates :name, presence: true, length: { maximum: 25 }
  validates :success_probability, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :dice_correction, presence: true, numericality: { only_integer: true, in: -10..10 }
  validates :damage, presence: true, length: { maximum: 15 }, format: {
    with: /\A\d+[dD]\d+(?:[+\-]\d+(?:[dD]\d+)?)*\z/,
    message: "は正しいダイスロール記法で入力してください（例: 1d6, 1d6+3, 1d6+1d3, 1d6-1d3）"
  }
  validates :attack_range, presence: true

  enum attack_range: { proximity: 1, ranged: 2 }

  belongs_to :character
end

class Attack < ApplicationRecord
  include DiceRollable

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

  def attack_roll
    dice_system.eval("CC#{dice_correction}<=#{success_probability}")
  end

  def success_correction(result)
    levels = {
      "クリティカル" => "c",
      "イクストリーム成功" => "e",
      "ハード成功" => "h",
      "レギュラー成功" => "r"
    }

    levels.find { |key, _| result.text.include?(key) }&.last || "r"
    # 1. levels.findでlevelsから1組の配列を受け取るために、ハッシュの要素（キーと値のペア）を一つずつ取り出す
    # 2. [{ |key, _| attack_result.text.include?(key) }] 1.にて取り出した[key]の中から値が一致するものを探し、その配列を取り出す("r"などの方は無視するために"_"にする)
    # 3. [&.last] 2.で取り出された配列の最後の要素("r"などの単文字の方)を取り出す。
    # 4. nilガードとして、[&.](帰り値がnilだった場合、nil.last(エラー)にせずnilのままにする)と[|| "r"](式の値がnilの場合"r"を代入)を設定
  end

  def damage_roll(damage_bonus)
    damage_command = damage
    damage_command += "+#{damage_bonus}" if proximity?
    dice_system.eval(damage_command)
  end
end

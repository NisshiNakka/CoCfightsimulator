FactoryBot.define do
  factory :attack do
    name { Faker::Game.title.truncate(25) }
    success_probability { Faker::Number.between(from: 1, to: 100) }
    dice_correction { Faker::Number.between(from: 0, to: 10) }
    damage { '1d6' }
    attack_range { Attack.attack_ranges.keys.sample }
    association :character
  end
end

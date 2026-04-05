FactoryBot.define do
  factory :user_dice_unlock do
    association :user
    dice_key { User::COLLECTABLE_DICE_KEYS.first }

    trait :cat_azuki do
      dice_key { "cat/cat_azuki_webp" }
    end

    trait :color_black do
      dice_key { "color/black" }
    end
  end
end

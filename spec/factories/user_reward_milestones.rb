FactoryBot.define do
  factory :user_reward_milestone do
    association :user
    milestone_key { "first_registration" }

    trait :first_character_create do
      milestone_key { "first_character_create" }
    end

    trait :first_simulation do
      milestone_key { "first_simulation" }
    end

    trait :characters_3 do
      milestone_key { "characters_3" }
    end
  end
end

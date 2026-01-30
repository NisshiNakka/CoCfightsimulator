FactoryBot.define do
  factory :character do
    name { Faker::Name.name.truncate(50) }
    hitpoint { Faker::Number.between(from: 3, to: 100) }
    dexterity { Faker::Number.between(from: 1, to: 200) }
    evasion_rate { Faker::Number.between(from: 1, to: 100) }
    evasion_correction { Faker::Number.between(from: -10, to: 10) }
    armor { Faker::Number.between(from: 0, to: 20) }
    damage_bonus { '1d3' }
    association :user

    after(:build) do |character|
      character.attacks << build(:attack, character: character) if character.attacks.empty?
    end

    after(:create) do |character|
      create(:attack, character: character) if character.attacks.empty?
    end

    trait :without_attacks do
      after(:create) do |character|
        character.attacks.destroy_all
      end
    end

    factory :quick_character do
      hitpoint { 20 }
      dexterity { 60 }
      evasion_rate { 1 }
      evasion_correction { -2 }
      armor { 0 }
    end

    factory :slow_character do
      hitpoint { 20 }
      dexterity { 40 }
      evasion_rate { 1 }
      evasion_correction { -2 }
      armor { 0 }
    end
  end
end

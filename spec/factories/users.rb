FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "test-#{n}@example.com" }
    password { Faker::Internet.password }
    password_confirmation { password }

    trait :google_oauth do
      sequence(:uid) { |n| "google_uid_#{n}" }
      provider { "google_oauth2" }
      password { nil }
      password_confirmation { nil }
    end
  end
end

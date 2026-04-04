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

    trait :with_site_icon do
      site_icon { "cat/cat_azuki_webp" }
    end

    trait :site_icon_hidden do
      site_icon { "none" }
    end
  end
end

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "test-#{n}@example.com" }
    password { Faker::Internet.password }
    password_confirmation { password }
  end
end

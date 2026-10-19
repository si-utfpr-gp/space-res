FactoryBot.define do
  factory :campus do
    sequence(:name) { |n| "Campus #{n}" }
  end
end

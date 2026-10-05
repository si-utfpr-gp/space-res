FactoryBot.define do
  factory :building do
    campus
    sequence(:name) { |n| "Bloco #{n}" }
  end
end

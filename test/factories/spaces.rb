FactoryBot.define do
  factory :space do
    campus
    sequence(:name) { |n| "Sala #{n}" }

    trait :with_building do
      building { association :building, campus: campus }
    end

    trait :requiring_approval do
      requires_approval { true }
    end

    trait :unavailable do
      status { :unavailable }
      unavailability_reason { "Sala em reforma" }
    end

    trait :deactivated do
      status { :deactivated }
    end
  end
end

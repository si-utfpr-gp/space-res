FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Departamento #{n}" }
  end
end

FactoryBot.define do
  factory :usage_term do
    sequence(:title) { |n| "Termo de uso #{n}" }
    content { Faker::Lorem.paragraphs(number: 2).map { |paragraph| "<div>#{paragraph}</div>" }.join }
  end
end

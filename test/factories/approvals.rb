FactoryBot.define do
  factory :approval do
    status { "MyString" }
    data_aprovacao { "2026-06-24 23:02:15" }
    justificativa { "MyText" }
    reservation { nil }
    sector { nil }
    aprovador { nil }
  end
end

FactoryBot.define do
  factory :reservation_date do
    data { "2026-06-24" }
    status { "MyString" }
    bloqueado_ate { "2026-06-24 23:02:09" }
    reservation { nil }
  end
end

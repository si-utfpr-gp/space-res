FactoryBot.define do
  factory :reservation do
    tipo_reserva { "MyString" }
    status { "MyString" }
    recorrencia { "MyString" }
    user { nil }
    space { nil }
  end
end

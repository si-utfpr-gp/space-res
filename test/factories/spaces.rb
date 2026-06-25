FactoryBot.define do
  factory :space do
    nome { "MyString" }
    descricao { "MyString" }
    tipo_espaco { "MyString" }
    capacidade { 1 }
    status { false }
    requer_aprovacao { false }
    sector { nil }
  end
end

User.find_or_create_by!(email_address: "admin@utfpr.edu.br") do |u|
  u.name = "Admin"
  u.password = "123456"
  u.tipo_usuario = "admin"
end

User.find_or_create_by!(email_address: "aluno@utfpr.edu.br") do |u|
  u.name = "Aluno1"
  u.password = "123456"
  u.tipo_usuario = "student"
end

sector = Sector.find_or_create_by!(nome: "TI") do |s|
  s.responsavel_id = User.find_by(email_address: "admin@utfpr.edu.br").id
end

Space.find_or_create_by!(nome: "Sala 101") do |s|
  s.tipo_espaco = "sala"
  s.capacidade = 30
  s.status = true
  s.requer_aprovacao = false
  s.sector = sector
end

Space.find_or_create_by!(nome: "Lab de Informática") do |s|
  s.tipo_espaco = "laboratorio"
  s.capacidade = 20
  s.status = true
  s.requer_aprovacao = true
  s.sector = sector
end
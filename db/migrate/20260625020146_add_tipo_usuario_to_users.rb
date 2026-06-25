class AddTipoUsuarioToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :tipo_usuario, :string
  end
end

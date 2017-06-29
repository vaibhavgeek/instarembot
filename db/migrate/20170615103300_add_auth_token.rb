class AddAuthToken < ActiveRecord::Migration[5.1]
  def change
  	add_column :messages , :auth_token , :string
  end
end

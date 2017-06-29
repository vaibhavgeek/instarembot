class AddIt < ActiveRecord::Migration[5.1]
  def change
  	add_column :messages , :from , :string
  end
end

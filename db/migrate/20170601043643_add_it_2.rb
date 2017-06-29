class AddIt2 < ActiveRecord::Migration[5.1]
  def change
  	  	remove_column :messages , :from , :string
  	add_column :messages , :from_id , :string

  end
end

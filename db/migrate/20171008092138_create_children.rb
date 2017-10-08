class CreateChildren < ActiveRecord::Migration[5.1]
  def change
    create_table :children do |t|
      t.string :first_name
      t.string :last_name
      t.boolean :active

      t.timestamps
    end
  end
end

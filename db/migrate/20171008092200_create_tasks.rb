class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :name
      t.integer :points
      t.boolean :active

      t.timestamps
    end
  end
end

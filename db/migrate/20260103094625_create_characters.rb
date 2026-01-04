class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters do |t|
      t.string :name, null: false, limit: 50
      t.integer :hitpoint, null: false
      t.integer :dexterity, null: false
      t.integer :evasion_rate, null: false
      t.integer :evasion_correction, null: false, default: 0
      t.integer :armor, null: false, default: 0
      t.string :damage_bonus, limit: 15, null: false, default: '0'
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end

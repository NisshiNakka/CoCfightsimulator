class CreateAttacks < ActiveRecord::Migration[7.0]
  def change
    create_table :attacks do |t|
      t.string :name, null: false, limit: 25
      t.integer :success_probability, null: false
      t.integer :dice_correction, null: false, default: 0
      t.string :damage, limit: 15, null: false
      t.integer :attack_range, null: false, default: 1
      t.references :character, foreign_key: true, null: false

      t.timestamps
    end
  end
end

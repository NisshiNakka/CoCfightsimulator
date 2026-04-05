class CreateUserDiceUnlocks < ActiveRecord::Migration[7.0]
  def change
    create_table :user_dice_unlocks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :dice_key, null: false

      t.timestamps
    end

    add_index :user_dice_unlocks, [ :user_id, :dice_key ], unique: true
  end
end

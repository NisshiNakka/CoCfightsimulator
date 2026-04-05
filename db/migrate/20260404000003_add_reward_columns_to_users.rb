class AddRewardColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :reward_tickets, :integer, null: false, default: 0
    add_column :users, :simulations_count, :integer, null: false, default: 0
    add_column :users, :character_edits_count, :integer, null: false, default: 0
    add_column :users, :dice_updates_count, :integer, null: false, default: 0
  end
end

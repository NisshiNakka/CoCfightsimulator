class CreateUserRewardMilestones < ActiveRecord::Migration[7.0]
  def change
    create_table :user_reward_milestones do |t|
      t.references :user, null: false, foreign_key: true
      t.string :milestone_key, null: false

      t.timestamps
    end

    add_index :user_reward_milestones, [ :user_id, :milestone_key ], unique: true
  end
end

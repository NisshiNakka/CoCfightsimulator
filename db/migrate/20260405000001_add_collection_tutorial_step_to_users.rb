class AddCollectionTutorialStepToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :collection_tutorial_step, :integer, default: 0, null: false
  end
end

class AddSiteIconToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :site_icon, :string, default: "defaults", null: false
  end
end

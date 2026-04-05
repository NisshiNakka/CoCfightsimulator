class UserDiceUnlock < ApplicationRecord
  belongs_to :user

  validates :dice_key, presence: true,
                       inclusion: { in: ->(_record) { User::COLLECTABLE_DICE_KEYS } },
                       uniqueness: { scope: :user_id }
end

class UserRewardMilestone < ApplicationRecord
  belongs_to :user

  validates :milestone_key, presence: true,
                             uniqueness: { scope: :user_id }
end

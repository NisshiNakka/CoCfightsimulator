class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :name, presence: true, length: { maximum: 50 }

  has_many :characters, dependent: :destroy

  TUTORIAL_LAST_STEP = 6

  def tutorial_active?
    tutorial_step > 0
  end

  def advance_tutorial!
    next_step = tutorial_step + 1
    update!(tutorial_step: next_step <= TUTORIAL_LAST_STEP ? next_step : 0)
  end

  def dismiss_tutorial!
    update!(tutorial_step: 0)
  end
end

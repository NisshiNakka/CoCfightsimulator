require "bcdice"

module DiceRollable
  extend ActiveSupport::Concern

  private

  def dice_system
    BCDice.game_system_class("Cthulhu7th")
  end
end

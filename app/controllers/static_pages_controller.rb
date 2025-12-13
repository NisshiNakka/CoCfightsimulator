class StaticPagesController < ApplicationController
  def top; end

  def roll
    begin
      require "bcdice"
      require "bcdice/game_system"

      # BCDiceのインスタンスを作成(alpha版の方法)
      # bcdice = BCDice.game_system_class('Cthulhu7th')
      # bcdice = BCDice::GameSystem::Cthulhu7th.new
      # alpha版では引数が必要
      # bcdice = game_system_class.new('Cthulhu7th')
      cthulhu7th = BCDice.game_system_class("Cthulhu7th")

      # ダイスコマンドを実行
      result = cthulhu7th.eval(params[:command])

      if result
        @result_text = result.text
        @success = result.success?
        @critical = result.critical?
        @fumble = result.fumble?
      else
        @result_text = "無効なコマンドです"
        @success = false
      end
    rescue => e
      Rails.logger.error("BCDice Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @result_text = "エラーが発生しました: #{e.message}"
      @success = false
    end

    respond_to do |format|
      format.turbo_stream
    end
  end
end

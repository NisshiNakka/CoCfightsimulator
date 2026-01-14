class SimulationsController < ApplicationController
  def new
    @all_characters = current_user.characters.order(created_at: :desc)
    # プルダウンで選択されたIDがある場合のみ検索を実行
    if params[:character_id].present?
      @character = @all_characters.includes(:attacks).find(params[:character_id])
    end
  end

  def show; end

  def roll
    begin
      cthulhu7th = BCDice.game_system_class("Cthulhu7th")
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

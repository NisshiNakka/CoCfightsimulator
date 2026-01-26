class SimulationsController < ApplicationController
  def new
    @all_characters = current_user.characters.order(created_at: :desc)

    if params.has_key?(:enemy_id)
      session[:enemy_id] = params[:enemy_id].presence
    end
    if params.has_key?(:ally_id)
      session[:ally_id] = params[:ally_id].presence
    end

    @enemy_character = @all_characters.includes(:attacks).find_by(id: session[:enemy_id])
    @ally_character = @all_characters.includes(:attacks).find_by(id: session[:ally_id])

    respond_to do |format|
      format.html
      format.turbo_stream
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
        @hard = @result_text.include?("ハード成功")
        @extreme = @result_text.include?("イクストリーム成功")
        @regular = @result_text.include?("成功") && !@hard && !@extreme
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

  def combat_roll
    ally_character = current_user.characters.includes(:attacks).find_by(id: session[:ally_id])
    enemy_character = current_user.characters.includes(:attacks).find_by(id: session[:enemy_id])
    return render_error("キャラクターが見つかりませんでした") if ally_character.nil? || enemy_character.nil?

    ally_attack = ally_character.attacks.first
    enemy_attack = enemy_character.attacks.first
    return render_error("攻撃技能が見つかりませんでした") if ally_attack.nil? || enemy_attack.nil?

    ally_result = BattleProcessor.call(ally_character, enemy_character, ally_attack).merge(side: :ally)
    enemy_result = BattleProcessor.call(enemy_character, ally_character, enemy_attack).merge(side: :enemy)

    @sorted_results = [ ally_result, enemy_result ].sort_by { |r| -r[:dexterity] }

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end
end

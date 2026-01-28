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

    session[:ally_hp] = @ally_character.hitpoint if @ally_character
    session[:enemy_hp] = @enemy_character.hitpoint if @enemy_character

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
    # 1. 値の取得(controllerの役割)
    ally_character = current_user.characters.includes(:attacks).find_by(id: session[:ally_id])
    enemy_character = current_user.characters.includes(:attacks).find_by(id: session[:enemy_id])
    return render_error("キャラクターが見つかりませんでした") if ally_character.nil? || enemy_character.nil?

    ally_attack = ally_character.attacks.first
    enemy_attack = enemy_character.attacks.first
    return render_error("攻撃技能が見つかりませんでした") if ally_attack.nil? || enemy_attack.nil?

    # 2. 戦闘順番の決定
    combatants = [
      { attacker: ally_character, defender: enemy_character, attack: ally_attack, side: :ally },
      { attacker: enemy_character, defender: ally_character, attack: enemy_attack, side: :enemy }
    ].sort_by { |c| -c[:attacker].dexterity }

    # 3. 渡す結果の決定 ()
    @sorted_results = []

    combatants.each do |c|
      ally_hp = session[:ally_hp] || ally_character.hitpoint
      enemy_hp = session[:enemy_hp] || enemy_character.hitpoint

      target_hp = (c[:side] == :ally) ? enemy_hp : ally_hp

      result = BattleProcessor.call(c[:attacker], c[:defender], c[:attack], target_hp).merge(side: c[:side])
      @sorted_results << result

      if result[:remaining_hp]
        if c[:side] == :ally
          session[:enemy_hp] = result[:remaining_hp]
        else
          session[:ally_hp] = result[:remaining_hp]
        end
      end

      if result[:remaining_hp]
        break if result[:remaining_hp] <= 0
      end
    end

    if (session[:ally_hp] || 1) <= 0 || (session[:enemy_hp] || 1) <= 0
      session.delete(:ally_hp)
      session.delete(:enemy_hp)
    end

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end
end

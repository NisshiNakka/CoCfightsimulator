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
    # 1. 値の取得(controllerの役割 :各メソッドへの値の取得と受け渡し)
    ally_character = current_user.characters.includes(:attacks).find_by(id: session[:ally_id])
    enemy_character = current_user.characters.includes(:attacks).find_by(id: session[:enemy_id])
    return render_error("キャラクターが見つかりませんでした") if ally_character.nil? || enemy_character.nil?

    ally_attack = ally_character.attacks.first
    enemy_attack = enemy_character.attacks.first
    return render_error("攻撃技能が見つかりませんでした") if ally_attack.nil? || enemy_attack.nil?

    # 2. 戦闘順番の決定(characterモデルまたはbattle_processorの役割？？ :データを元に配列の並び替えを行う)(コアな処理)
    combatants = [
      { attacker: ally_character, defender: enemy_character, attack: ally_attack, side: :ally, target_hp_key: :enemy_hp },
      { attacker: enemy_character, defender: ally_character, attack: enemy_attack, side: :enemy, target_hp_key: :ally_hp }
    ].sort_by { |c| -c[:attacker].dexterity }

    # 3. 渡す結果の決定 (controllerの役割 :viewへの仲介)
    @sorted_results = []

    # 4. 戦闘の実行 (battle_processorに譲渡済み これ以上battle_processorへ移行させられる部分はない？)
    combatants.each do |c|
      target_hp = session[c[:target_hp_key]] || c[:defender].hitpoint

      result = BattleProcessor.call(c[:attacker], c[:defender], c[:attack], target_hp).merge(side: c[:side])
      @sorted_results << result

      # 状態の保存（役割不明 :sessionの管理はコントローラーにしか適した場所がない？）
      if result[:remaining_hp]
        session[c[:target_hp_key]] = result[:remaining_hp]# (コアな処理?)
      end

      break if c[:defender].defeated?(result[:remaining_hp] || 1)
    end

    # リセット判定（役割不明 :sessionの管理はコントローラーにしか適した場所がない？）
    if ally_character.defeated?(session[:ally_hp] || 1) || enemy_character.defeated?(session[:enemy_hp] || 1)
      session.delete(:ally_hp)
      session.delete(:enemy_hp)
    end

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end
end

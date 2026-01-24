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
    ally_character = current_user.characters.find_by(id: session[:ally_id])
    enemy_character = current_user.characters.find_by(id: session[:enemy_id])
    ally_attack = ally_character.attacks.first
    enemy_attack = enemy_character.attacks.first

    ally_result = execute_attack(ally_character, enemy_character, ally_attack).merge(side: :ally, order: ally_character.dexterity)
    enemy_result = execute_attack(enemy_character, ally_character, enemy_attack).merge(side: :enemy, order: enemy_character.dexterity)

    @sorted_results = [ ally_result, enemy_result ].sort_by { |r| -r[:order] }

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end

  private

  def execute_attack(attacker, defender, use_attack)
    cthulhu7th = BCDice.game_system_class("Cthulhu7th")
    attack_result = cthulhu7th.eval("CC#{use_attack.dice_correction}<=#{use_attack.success_probability}")

    unless attack_result.success?
      return {
        text: "#{attacker.name}の攻撃失敗(#{attack_result.text})",
        success: false,
        status: "失敗"
      }
    end

    levels = {
      "クリティカル" => "c",
      "イクストリーム成功" => "e",
      "ハード成功" => "h",
      "レギュラー成功" => "r"
    }

    correction = levels.find { |key, _| attack_result.text.include?(key) }&.last || "r"
    # 1. levels.findでlevelsから1組の配列を受け取るために、ハッシュの要素（キーと値のペア）を一つずつ取り出す
    # 2. [{ |key, _| attack_result.text.include?(key) }] 1.にて取り出した[key]の中から値が一致するものを探し、その配列を取り出す("r"などの方は無視するために"_"にする)
    # 3. [&.last] 2.で取り出された配列の最後の要素("r"などの単文字の方)を取り出す。
    # 4. nilガードとして、[&.](帰り値がnilだった場合、nil.last(エラー)にせずnilのままにする)と[|| "r"](式の値がnilの場合"r"を代入)を設定

    evasion_result = cthulhu7th.eval("CC#{defender.evasion_correction}<=#{defender.evasion_rate}#{correction}")

    if evasion_result.success?
      {
        text: "#{attacker.name}の攻撃成功(#{attack_result.text}\n ── しかし#{defender.name}が回避(#{evasion_result.text})",
        status: "回避",
        success: false
    }
    else
      damage_cmd = use_attack.damage
      damage_cmd += "+#{attacker.damage_bonus}" if use_attack.proximity?
      damage_roll = cthulhu7th.eval(damage_cmd)
      damage_value = damage_roll.text.split(" ＞ ").last.to_i
      remaining_hp = defender.hitpoint - damage_value

      {
        text: "#{attacker.name}の攻撃成功(#{attack_result.text})\n ── #{defender.name}は回避失敗(#{evasion_result.text})\n ── #{defender.name}へのダメージ: #{damage_roll.text}(残りHP: #{remaining_hp})",
        status: "成功",
        success: true
    }
    end
  end
end

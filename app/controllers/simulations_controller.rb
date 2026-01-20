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
    if params[:attacker_side] == "ally"
      attacker = current_user.characters.find_by(id: session[:ally_id])
      defender = current_user.characters.find_by(id: session[:enemy_id])
    else
      attacker = current_user.characters.find_by(id: session[:enemy_id])
      defender = current_user.characters.find_by(id: session[:ally_id])
    end

    attack_judgment(attacker, defender, params[:skill_value], params[:skill_correction])

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end

  private

  def attack_judgment(attacker, defender, skill_value, skill_correction)
    cthulhu7th = BCDice.game_system_class("Cthulhu7th")
    attack_result = cthulhu7th.eval("CC#{skill_correction}<=#{skill_value}")

    unless attack_result.success?
      @status = "失敗"
      @result_text = "#{attacker.name}の攻撃失敗(#{attack_result.text})"
      @success = false
      return
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

    evasion_command = "CC#{defender.evasion_correction}<=#{defender.evasion_rate}#{correction}"
    evasion_result = cthulhu7th.eval(evasion_command)

    if evasion_result.success?
      @status = "失敗"
      @result_text = "#{attacker.name}の攻撃成功(#{attack_result.text}) ── しかし#{defender.name}が回避(#{evasion_result.text})"
      @success = false
    else
      @status = "成功"
      @result_text = "#{attacker.name}の攻撃成功(#{attack_result.text}) ── #{defender.name}は回避失敗(#{evasion_result.text})"
      @success = true
    end
  end
end
